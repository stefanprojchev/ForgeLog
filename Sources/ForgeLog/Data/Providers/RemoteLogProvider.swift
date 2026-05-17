import Foundation
import ForgeCore

/// Batches log entries and sends them to a remote endpoint. Handles batching,
/// flush intervals, and offline resilience (re-queues on transient failures).
///
/// ```swift
/// let remote = RemoteLogProvider(
///     endpoint: URL(string: "https://api.example.com/logs")!,
///     headers: ["Authorization": "Bearer token123"],
///     batchSize: 50,
///     flushInterval: 30
/// )
/// ForgeLog.shared.addProvider(remote)
/// ```
///
/// Custom body transformation:
/// ```swift
/// let custom = RemoteLogProvider(
///     endpoint: URL(string: "https://api.example.com/logs")!,
///     bodyTransformer: { entries in
///         let payload = ["logs": entries.map { ["msg": $0.message, "level": $0.level.label] }]
///         return try JSONSerialization.data(withJSONObject: payload)
///     }
/// )
/// ```
public final class RemoteLogProvider: LogProviderProtocol {
    // MARK: - Dependencies

    public let name: String = "RemoteLogProvider"
    public let minimumLevel: LogLevel
    private let endpoint: URL
    private let headers: [String: String]
    private let batchSize: Int
    private let flushInterval: TimeInterval
    private let bodyTransformer: (@Sendable ([LogEntry]) throws -> Data)?
    private let session: URLSession
    private let maxPendingEntries: Int
    private let queue: DispatchQueue
    private let encoder: JSONEncoder
    private let state: LockedState<InternalState>

    // MARK: - Init

    /// - Parameters:
    ///   - endpoint: The URL to POST batched log entries to.
    ///   - headers: Additional HTTP headers (e.g., authorization).
    ///   - batchSize: Number of entries to accumulate before auto-flushing. Default: 50.
    ///   - flushInterval: Seconds between time-based flushes. Default: 30.
    ///   - minimumLevel: Minimum log level to send remotely. Default: `.debug`.
    ///   - maxPendingEntries: Maximum entries to keep in memory. Oldest dropped when exceeded. Default: 1000.
    ///   - session: URLSession to use for requests.
    ///   - bodyTransformer: Optional custom transformation from entries to request body data.
    ///                      If `nil`, entries are encoded as a JSON array of `LogEntry`.
    public init(
        endpoint: URL,
        headers: [String: String] = [:],
        batchSize: Int = 50,
        flushInterval: TimeInterval = 30,
        minimumLevel: LogLevel = .debug,
        maxPendingEntries: Int = 1000,
        session: URLSession = .shared,
        bodyTransformer: (@Sendable ([LogEntry]) throws -> Data)? = nil
    ) {
        self.endpoint = endpoint
        self.headers = headers
        self.batchSize = batchSize
        self.flushInterval = flushInterval
        self.minimumLevel = minimumLevel
        self.maxPendingEntries = maxPendingEntries
        self.session = session
        self.bodyTransformer = bodyTransformer
        self.queue = DispatchQueue(label: "com.forgelog.RemoteLogProvider", qos: .utility)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        self.state = LockedState(InternalState(pendingEntries: [], flushTimer: nil))

        startFlushTimer()
    }

    deinit {
        let remaining: [LogEntry] = state.withLock { s in
            s.flushTimer?.cancel()
            s.flushTimer = nil
            let snapshot = s.pendingEntries
            s.pendingEntries.removeAll()
            return snapshot
        }

        if !remaining.isEmpty {
            // Best-effort synchronous send before deallocation.
            sendEntries(remaining)
        }
    }

    // MARK: - Implementation

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        let shouldFlush = state.withLock { s -> Bool in
            s.pendingEntries.append(entry)
            return s.pendingEntries.count >= batchSize
        }

        if shouldFlush {
            flush()
        }
    }

    /// Immediately sends all pending entries to the remote endpoint.
    public func flush() {
        let entriesToSend = state.withLock { s -> [LogEntry] in
            let snapshot = s.pendingEntries
            s.pendingEntries.removeAll(keepingCapacity: true)
            return snapshot
        }

        guard !entriesToSend.isEmpty else { return }

        queue.async { [weak self] in
            self?.sendEntries(entriesToSend)
        }
    }

    // MARK: - Private

    private struct InternalState {
        var pendingEntries: [LogEntry]
        var flushTimer: DispatchSourceTimer?
    }

    private func startFlushTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + flushInterval, repeating: flushInterval)
        timer.setEventHandler { [weak self] in
            self?.flush()
        }
        timer.resume()

        state.withLock { $0.flushTimer = timer }
    }

    private func requeue(_ entries: [LogEntry]) {
        let cap = maxPendingEntries
        state.withLock { s in
            s.pendingEntries.insert(contentsOf: entries, at: 0)
            if s.pendingEntries.count > cap {
                s.pendingEntries.removeFirst(s.pendingEntries.count - cap)
            }
        }
    }

    private func sendEntries(_ entries: [LogEntry]) {
        let body: Data
        do {
            if let transformer = bodyTransformer {
                body = try transformer(entries)
            } else {
                body = try encoder.encode(entries)
            }
        } catch {
            print("[RemoteLogProvider] Failed to encode log entries: \(error.localizedDescription)")
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let task = session.dataTask(with: request) { [weak self] _, response, error in
            guard let self else { return }

            if let error {
                print("[RemoteLogProvider] Failed to send logs: \(error.localizedDescription)")
                self.requeue(entries)
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("[RemoteLogProvider] Server returned status \(httpResponse.statusCode)")
                // Re-queue only on 5xx (transient). 4xx are dropped.
                if (500...599).contains(httpResponse.statusCode) {
                    self.requeue(entries)
                }
            }
        }
        task.resume()
    }
}
