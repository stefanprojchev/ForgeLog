import Foundation
import Combine

/// Observable backing store for the network viewer — sibling of
/// `LogViewerStore` in ForgeLog. Owned by `ForgeNet.shared.store` and shared
/// between the capture layer (URLProtocol) and the views.
///
/// `filteredEntries` is a **computed property**, not a `@Published` one — the
/// same lesson learned for `LogViewerStore`. ObservableObject already
/// re-invalidates the view on any `@Published` change; computing
/// `filteredEntries` on demand keeps the view in sync without the async
/// `receive(on:)` gap a Combine pipeline introduces.
@MainActor
public final class NetworkLogStore: ObservableObject {
    @Published public private(set) var entries: [NetworkLogEntry] = []
    @Published public var filter: NetworkFilterState = NetworkFilterState()
    @Published public var isPaused: Bool = false
    @Published public private(set) var rate: Double = 0

    public let configuration: ForgeNetConfiguration
    public let sessionID: UUID = UUID()
    public let sessionStarted: Date = Date()

    private var cancellables: Set<AnyCancellable> = []

    public init(configuration: ForgeNetConfiguration = .default) {
        self.configuration = configuration
        setupRatePublisher()
    }

    // MARK: - Derived data

    /// Entries that pass the current filter, ordered newest-first for the
    /// list view.
    public var filteredEntries: [NetworkLogEntry] {
        entries.reversed().filter(filter.matches)
    }

    /// Total bytes transferred this session (request + response combined).
    public var totalBytes: Int {
        entries.reduce(0) { $0 + $1.requestBytes + $1.responseBytes }
    }

    // MARK: - Public actions

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

    // MARK: - Universe queries (for filter pickers and stats)

    public var allHosts: [String] {
        Array(Set(entries.map(\.host))).sorted()
    }

    public var allMethods: [HTTPMethod] {
        Array(Set(entries.map(\.method))).sorted { $0.order < $1.order }
    }

    public var allCallers: [String] {
        Array(Set(entries.compactMap(\.callerModule))).sorted()
    }

    public func count(for family: HTTPStatusFamily?) -> Int {
        guard let family else { return entries.count }
        return entries.lazy.filter { $0.statusFamily == family }.count
    }

    // MARK: - Append (called by the URLProtocol)

    nonisolated public func append(_ entry: NetworkLogEntry) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard !self.isPaused else { return }
            self.entries.append(entry)
            self.capEntries()
        }
    }

    // MARK: - Private

    private func setupRatePublisher() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .map { [weak self] _ -> Double in
                guard let self else { return 0 }
                let cutoff = Date().addingTimeInterval(-1)
                return Double(self.entries.lazy.filter { $0.timestamp >= cutoff }.count)
            }
            .assign(to: &$rate)
    }

    private func capEntries() {
        let cap = configuration.inMemoryLimit
        if entries.count > cap {
            entries.removeFirst(entries.count - cap)
        }
    }
}
