#if os(iOS) || os(visionOS)
import Foundation
import Combine

/// Configuration for the live in-memory log buffer that backs the inspector UI.
public struct LiveLogBufferConfiguration: Sendable {
    /// Maximum number of in-memory entries before oldest are evicted.
    public var inMemoryLimit: Int

    /// Minimum severity to surface in the viewer.
    public var minLevel: LogLevel

    public init(inMemoryLimit: Int = 5000, minLevel: LogLevel = .debug) {
        self.inMemoryLimit = inMemoryLimit
        self.minLevel = minLevel
    }

    public static let `default` = LiveLogBufferConfiguration()
}

/// In-memory ring buffer that subscribes to `ForgeLog` via a `LogViewerProvider`
/// and exposes the running stream to the inspector UI.
///
/// This is the **data-layer** counterpart of the viewer — it owns the entries,
/// pause flag, session metadata, and rate heartbeat. UI filter state lives on
/// the screen's view model (`LogListViewModel`).
@MainActor
@Observable
public final class LiveLogBuffer {
    // MARK: - Dependencies

    public let configuration: LiveLogBufferConfiguration
    public let sessionID: UUID = UUID()
    public let sessionStarted: Date = Date()

    // MARK: - Init

    /// Initializes the buffer and attaches a `LogViewerProvider` to `logger`.
    /// Entries flowing through `ForgeLog` from this point on will appear here.
    public init(
        configuration: LiveLogBufferConfiguration = .default,
        logger: ForgeLog = .shared
    ) {
        self.configuration = configuration
        self.logger = logger
        self.providers = logger.providerInfos
        setupRatePublisher()
        attachProvider()
    }

    // MARK: - Implementation

    public private(set) var entries: [LogEntry] = []
    public var isPaused: Bool = false
    public private(set) var rate: Double = 0
    public private(set) var providers: [ForgeLog.ProviderInfo] = []

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

    // MARK: - Private

    @ObservationIgnored private let logger: ForgeLog
    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []

    private func setupRatePublisher() {
        // Rate — entries/sec over the last 1s window. Independent of the
        // filter pipeline so it's just a heartbeat.
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let cutoff = Date().addingTimeInterval(-1)
                self.rate = Double(self.entries.lazy.filter { $0.timestamp >= cutoff }.count)
            }
            .store(in: &cancellables)
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
