import Foundation
import ForgeCore

/// The main logger for the Forge family.
///
/// Configure once at app launch (typically in `App.init` or the app delegate),
/// then use `ForgeLog.shared.info(...)`, `.warning(...)`, `.error(...)`, etc.
///
/// ```swift
/// ForgeLog.shared.configure()
///
/// ForgeLog.shared.info("App launched")
/// ForgeLog.shared.error("Sync failed", metadata: error)
/// ```
public final class ForgeLog: LoggerProtocol {
    // MARK: - State

    private struct State {
        var providers: [LogProviderProtocol]
        var configuration: LoggerConfiguration
        var isConfigured: Bool
    }

    private let state: LockedState<State>

    /// Thread-local key used to detect re-entrant logging (a provider calling
    /// the logger from inside its own `log()`). Stored in `Thread.threadDictionary`
    /// so it works in both sync and async contexts and is naturally thread-confined.
    private static let reentrantGuardKey = "com.forgelog.isDispatching"

    /// Shared singleton. Must be configured via `ForgeLog.shared.configure(...)` before use.
    public static let shared = ForgeLog()

    /// Default provider set: Print, Console, Disk, and CrashContext.
    ///
    /// - `PrintLogProvider` — Swift `print()` output (Xcode console)
    /// - `ConsoleLogProvider` — Apple `os.Logger` (Console.app)
    /// - `DiskLogProvider` — JSONL files on disk
    /// - `CrashContextProvider` — In-memory ring buffer for crash context
    ///
    /// For additional providers, use `LoggerConfiguration(providers:)` with a custom list.
    /// See also: `FileExportLogProvider`, `NotificationCenterLogProvider`,
    /// `FilteredLogProvider`, `RemoteLogProvider`.
    public static var defaultProviders: [LogProviderProtocol] {
        [
            PrintLogProvider(),
            ConsoleLogProvider(),
            DiskLogProvider(),
            CrashContextProvider(),
        ]
    }

    // MARK: - Init

    public init() {
        self.state = LockedState(
            State(
                providers: [],
                configuration: LoggerConfiguration(
                    providers: [],
                    maxAge: nil,
                    maxTotalSize: nil,
                    isDebugEnabled: true
                ),
                isConfigured: false
            )
        )
    }

    // MARK: - Configuration

    /// Configures the logger. Must be called before any logging occurs (typically at app launch).
    ///
    /// ```swift
    /// // Defaults:
    /// ForgeLog.shared.configure()
    ///
    /// // Custom:
    /// ForgeLog.shared.configure(LoggerConfiguration(
    ///     providers: ForgeLog.defaultProviders,
    ///     maxAge: .weeks(1),
    ///     isDebugEnabled: true
    /// ))
    /// ```
    public func configure(_ configuration: LoggerConfiguration = LoggerConfiguration()) {
        state.withLock { s in
            s.providers = configuration.providers
            s.configuration = configuration
            s.isConfigured = true
        }

        // Fire-and-forget purge.
        let maxAgeInterval = configuration.maxAgeInterval
        let maxTotalSizeBytes = configuration.maxTotalSizeBytes
        let store = LogStore()
        Task.detached(priority: .utility) {
            try? await store.purge(maxAge: maxAgeInterval, maxTotalSize: maxTotalSizeBytes)
        }
    }

    // MARK: - LoggerProtocol

    public func log(
        level: LogLevel,
        _ message: String,
        metadata: [String: AnyCodableValue]?,
        processes: [String],
        file: String,
        function: String,
        line: Int
    ) {
        let snapshot = state.withLock { s in
            (providers: s.providers, isConfigured: s.isConfigured, isDebugEnabled: s.configuration.isDebugEnabled)
        }

        if level == .debug, !snapshot.isDebugEnabled { return }

        dispatch(
            providers: snapshot.providers,
            isConfigured: snapshot.isConfigured,
            level: level,
            message: message,
            metadata: metadata,
            processes: processes,
            file: file,
            function: function,
            line: line
        )
    }

    public func addProvider(_ provider: LogProviderProtocol) {
        state.withLock { $0.providers.append(provider) }
    }

    @discardableResult
    public func removeProvider(named name: String) -> Bool {
        state.withLock { s in
            guard let index = s.providers.firstIndex(where: { $0.name == name }) else {
                return false
            }
            s.providers.remove(at: index)
            return true
        }
    }

    public func removeAllProviders() {
        state.withLock { $0.providers.removeAll() }
    }

    public var providerNames: [String] {
        state.withLock { $0.providers.map(\.name) }
    }

    /// The configured maximum age for log files (how long logs are kept before auto-purge).
    /// Returns `nil` if age-based purging is disabled.
    public var maxAge: LogAge? {
        state.withLock { $0.configuration.maxAge }
    }

    /// The configured maximum total size for log files.
    /// Returns `nil` if size-based purging is disabled.
    public var maxTotalSize: StorageSize? {
        state.withLock { $0.configuration.maxTotalSize }
    }

    /// Structured info about each active provider for display in settings UI.
    public var providerInfos: [ProviderInfo] {
        state.withLock { s in
            s.providers.map { ProviderInfo(name: $0.name, minimumLevel: $0.minimumLevel) }
        }
    }

    /// Lightweight snapshot of a registered provider.
    public struct ProviderInfo: Identifiable, Sendable {
        public let id: String
        public let name: String
        public let minimumLevel: LogLevel

        public init(name: String, minimumLevel: LogLevel) {
            self.id = name
            self.name = name
            self.minimumLevel = minimumLevel
        }
    }

    // MARK: - Private

    private func dispatch(
        providers: [LogProviderProtocol],
        isConfigured: Bool,
        level: LogLevel,
        message: String,
        metadata: [String: AnyCodableValue]?,
        processes: [String],
        file: String,
        function: String,
        line: Int
    ) {
        // Configuration guard: silently drops log entries before configure() is called.
        // Expected during app startup when ObjC +load methods may log before
        // configure() has been called.
        guard isConfigured else {
            #if DEBUG
            print("[ForgeLog] Logger not yet configured — dropping message: \(message)")
            #endif
            return
        }

        // Re-entrancy guard: prevents infinite recursion when a provider
        // synchronously calls back into ForgeLog from inside its log() method.
        // Uses a thread-local flag so concurrent logging from other threads is unaffected.
        let threadDict = Thread.current.threadDictionary
        if threadDict[Self.reentrantGuardKey] != nil {
            #if DEBUG
            fatalError("[ForgeLog] Re-entrant log call detected — a provider is calling ForgeLog from inside log(). This causes infinite recursion. Message: \(message)")
            #else
            return
            #endif
        }

        threadDict[Self.reentrantGuardKey] = true
        defer { threadDict.removeObject(forKey: Self.reentrantGuardKey) }

        let className = Self.extractClassName(from: file)
        let moduleName = Self.extractModuleName(from: file)

        let entry = LogEntry(
            level: level,
            message: message,
            className: className,
            functionName: function,
            line: line,
            processes: processes,
            module: moduleName,
            metadata: metadata
        )

        for provider in providers {
            provider.log(entry)
        }
    }

    /// Extracts class/file name from `#fileID` ("ModuleName/FileName.swift" → "FileName").
    static func extractClassName(from fileID: String) -> String {
        let fileName = fileID.split(separator: "/").last ?? Substring(fileID)
        return String(fileName.split(separator: ".").first ?? fileName)
    }

    /// Extracts module name from `#fileID` ("ModuleName/FileName.swift" → "ModuleName").
    static func extractModuleName(from fileID: String) -> String? {
        let parts = fileID.split(separator: "/")
        guard parts.count > 1 else { return nil }
        return String(parts.first!)
    }
}
