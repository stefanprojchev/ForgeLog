#if os(iOS) || os(visionOS)
import Foundation
import Combine

/// Observable backing buffer for the network viewer — sibling of
/// `LiveLogBuffer` in ForgeLog. Owned by `ForgeNet.shared.buffer` and shared
/// between the capture layer (URLProtocol) and the views.
@MainActor
@Observable
public final class NetworkLogBuffer {
    // MARK: - Dependencies

    public let configuration: ForgeNetConfiguration
    public let sessionID: UUID = UUID()
    public let sessionStarted: Date = Date()

    // MARK: - Init

    public init(configuration: ForgeNetConfiguration = .default) {
        self.configuration = configuration
        setupRatePublisher()
    }

    // MARK: - Implementation

    public private(set) var entries: [NetworkLogEntry] = []
    public var isPaused: Bool = false
    public private(set) var rate: Double = 0

    /// Total bytes transferred this session (request + response combined).
    public var totalBytes: Int {
        entries.reduce(0) { $0 + $1.requestBytes + $1.responseBytes }
    }

    public func clearSession() {
        entries.removeAll()
    }

    public func togglePause() {
        isPaused.toggle()
    }

    /// Append entries that already exist on disk (or were seeded for demo).
    public func backfill(_ pre: [NetworkLogEntry]) {
        entries.append(contentsOf: pre)
        capEntries()
    }

    /// Called by the URLProtocol from any thread when a request completes.
    nonisolated public func append(_ entry: NetworkLogEntry) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard !self.isPaused else { return }
            self.entries.append(entry)
            self.capEntries()
        }
    }

    // MARK: - Private

    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []

    private func setupRatePublisher() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let cutoff = Date().addingTimeInterval(-1)
                self.rate = Double(self.entries.lazy.filter { $0.timestamp >= cutoff }.count)
            }
            .store(in: &cancellables)
    }

    private func capEntries() {
        let cap = configuration.inMemoryLimit
        if entries.count > cap {
            entries.removeFirst(entries.count - cap)
        }
    }
}
#endif
