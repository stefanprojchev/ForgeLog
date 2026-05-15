import Foundation
import ForgeCore

/// A log provider that keeps the most recent log entries in a ring buffer.
/// Useful for attaching "what happened before the crash" context to crash reports.
///
/// ```swift
/// let crashContext = CrashContextProvider(bufferSize: 50)
/// ForgeLog.shared.configure(LoggerConfiguration(providers: [crashContext, ...]))
///
/// // In your crash reporter setup:
/// crashContext.recentEntries().forEach { entry in
///     Crashlytics.crashlytics().setCustomValue(entry.formattedMessage, forKey: "log_\(entry.id)")
/// }
/// ```
public final class CrashContextProvider: LogProviderProtocol {
    public let name: String = "CrashContextProvider"
    public let minimumLevel: LogLevel

    private let bufferSize: Int
    private let buffer: LockedState<RingBuffer>

    private struct RingBuffer {
        var entries: [LogEntry]
        var index: Int
    }

    /// - Parameters:
    ///   - bufferSize: Maximum number of recent entries to keep. Default: 100.
    ///   - minimumLevel: Minimum log level to capture.
    public init(
        bufferSize: Int = 100,
        minimumLevel: LogLevel = .debug
    ) {
        self.bufferSize = bufferSize
        self.minimumLevel = minimumLevel
        var initialEntries: [LogEntry] = []
        initialEntries.reserveCapacity(bufferSize)
        self.buffer = LockedState(RingBuffer(entries: initialEntries, index: 0))
    }

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        let capacity = bufferSize
        buffer.withLock { ring in
            if ring.entries.count < capacity {
                ring.entries.append(entry)
            } else {
                ring.entries[ring.index] = entry
            }
            ring.index = (ring.index + 1) % capacity
        }
    }

    /// Returns the recent log entries in chronological order.
    public func recentEntries() -> [LogEntry] {
        let capacity = bufferSize
        return buffer.withLock { ring in
            guard ring.entries.count == capacity else {
                return ring.entries
            }
            return Array(ring.entries[ring.index...]) + Array(ring.entries[..<ring.index])
        }
    }

    /// Returns recent entries formatted as a single string, suitable for crash report metadata.
    public func recentEntriesAsString() -> String {
        recentEntries().map(\.plainTextMessage).joined(separator: "\n")
    }

    /// Clears the buffer.
    public func clear() {
        buffer.withLock { ring in
            ring.entries.removeAll(keepingCapacity: true)
            ring.index = 0
        }
    }
}
