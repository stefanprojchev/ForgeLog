import Foundation

public struct LoggerConfiguration: Sendable {
    /// The providers that will receive log entries.
    ///
    /// Use `ForgeLog.defaultProviders` for the standard set (Print, Console, Disk, CrashContext),
    /// or supply a custom list.
    public let providers: [LogProviderProtocol]

    /// Maximum age of log files before they are purged. Default: 30 days.
    ///
    /// Files older than this are deleted during the automatic purge that runs at
    /// `configure()` time. Set to `nil` to disable age-based purging.
    public let maxAge: LogAge?

    /// Maximum total size of all log files on disk. Default: `nil` (no size limit).
    ///
    /// When the total size of log files exceeds this limit, the oldest files
    /// are deleted until the total is under the limit.
    public let maxTotalSize: StorageSize?

    /// Whether debug-level logs should be processed. Default: `true`.
    ///
    /// > Note: The `#if DEBUG` check must happen in your **app target** (not here)
    /// > because this library is compiled separately and its `#if DEBUG` reflects
    /// > the library's build configuration, not your app's.
    public let isDebugEnabled: Bool

    public init(
        providers: [LogProviderProtocol] = ForgeLog.defaultProviders,
        maxAge: LogAge? = .days(30),
        maxTotalSize: StorageSize? = nil,
        isDebugEnabled: Bool = true
    ) {
        self.providers = providers
        self.maxAge = maxAge
        self.maxTotalSize = maxTotalSize
        self.isDebugEnabled = isDebugEnabled
    }

    /// Raw seconds value for internal use by purge logic.
    var maxAgeInterval: TimeInterval? {
        guard let maxAge else { return nil }
        let interval = maxAge.timeInterval
        return interval > 0 ? interval : nil
    }

    /// Raw bytes value for internal use by purge logic.
    var maxTotalSizeBytes: Int64? {
        guard let maxTotalSize else { return nil }
        let bytes = maxTotalSize.bytes
        return bytes > 0 ? bytes : nil
    }
}
