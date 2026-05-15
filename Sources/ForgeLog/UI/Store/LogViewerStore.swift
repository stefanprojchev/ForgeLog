#if os(iOS) || os(visionOS)
import Foundation
import Combine

public struct LogViewerConfiguration: Sendable {
    /// Maximum number of in-memory entries before oldest are evicted.
    public var inMemoryLimit: Int

    /// Minimum severity to surface in the viewer.
    public var minLevel: LogLevel

    public init(inMemoryLimit: Int = 5000, minLevel: LogLevel = .debug) {
        self.inMemoryLimit = inMemoryLimit
        self.minLevel = minLevel
    }

    public static let `default` = LogViewerConfiguration()
}

/// Observable backing store for `ForgeLogView`. Hosts the live in-memory ring,
/// filter state, and rate. Itself a thin layer on top of `ForgeLog` — it
/// subscribes via a `LogViewerProvider` registered into `ForgeLog.shared`.
///
/// `filteredEntries` is intentionally a **computed property**, not a
/// `@Published` one. This avoids the asynchronous propagation gap that a
/// Combine pipeline (`receive(on: .main).assign(to: &$filteredEntries)`)
/// introduces — when SwiftUI re-renders after a filter change, the body
/// reads the latest filter+entries directly, so the result is correct on
/// the same runloop tick. With ObservableObject, any `@Published` change
/// (filter, entries, isPaused, ...) re-invalidates observing views, which
/// re-reads `filteredEntries` and recomputes.
@MainActor
public final class LogViewerStore: ObservableObject {
    @Published public private(set) var entries: [LogEntry] = []
    @Published public var filter: FilterState = FilterState()
    @Published public var isPaused: Bool = false
    @Published public private(set) var rate: Double = 0

    public let configuration: LogViewerConfiguration
    public let sessionID: UUID = UUID()
    public let sessionStarted: Date = Date()

    /// Names of providers currently registered on `ForgeLog.shared`. Populated
    /// on init; refresh via `refreshProviders()` if you mutate providers later.
    @Published public private(set) var providers: [ForgeLog.ProviderInfo] = []

    private let logger: ForgeLog
    private var cancellables: Set<AnyCancellable> = []

    /// Initializes the store and attaches a `LogViewerProvider` to `logger`.
    /// Entries flowing through `ForgeLog` from this point on will appear here.
    public init(
        configuration: LogViewerConfiguration = .default,
        logger: ForgeLog = .shared
    ) {
        self.configuration = configuration
        self.logger = logger
        self.providers = logger.providerInfos
        setupRatePublisher()
        attachProvider()
    }

    // MARK: - Public actions

    public func clearSession() {
        entries.removeAll()
    }

    public func togglePause() {
        isPaused.toggle()
    }

    public func refreshProviders() {
        providers = logger.providerInfos
    }

    /// Append entries that already exist on disk for a given day.
    /// Use to backfill the viewer with prior-session data.
    public func backfill(_ pre: [LogEntry]) {
        entries.append(contentsOf: pre)
        capEntries()
    }

    // MARK: - Derived data

    /// Entries that pass the current filter, ordered newest-first for the list
    /// view. Computed (not `@Published`) so it always reflects the latest
    /// `entries` + `filter` synchronously.
    public var filteredEntries: [LogEntry] {
        entries.reversed().filter(filter.matches)
    }

    // MARK: - Universe queries (for filter pickers and stats)

    public var allModules: [String] {
        Array(Set(entries.compactMap(\.module))).sorted()
    }

    public var allClasses: [String] {
        Array(Set(entries.map(\.className))).sorted()
    }

    public var allProcesses: [String] {
        Array(Set(entries.flatMap(\.processes))).sorted()
    }

    public func count(for level: LogLevel?) -> Int {
        guard let level else { return entries.count }
        return entries.lazy.filter { $0.level == level }.count
    }

    // MARK: - Private

    private func setupRatePublisher() {
        // Rate — entries/sec over the last 1s window. Independent of the
        // filter pipeline so it's just a heartbeat.
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .map { [weak self] _ -> Double in
                guard let self else { return 0 }
                let cutoff = Date().addingTimeInterval(-1)
                return Double(self.entries.lazy.filter { $0.timestamp >= cutoff }.count)
            }
            .assign(to: &$rate)
    }

    private func attachProvider() {
        // Weak self via a tiny closure-only handle. The provider is `Sendable`
        // and may fire on any thread — we hop to main to mutate `entries`.
        let provider = LogViewerProvider(minimumLevel: configuration.minLevel) { [weak self] entry in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard !self.isPaused else { return }
                self.entries.append(entry)
                self.capEntries()
            }
        }
        logger.addProvider(provider)
        refreshProviders()
    }

    private func capEntries() {
        let cap = configuration.inMemoryLimit
        if entries.count > cap {
            entries.removeFirst(entries.count - cap)
        }
    }
}
#endif
