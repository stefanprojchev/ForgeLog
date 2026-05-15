import Foundation

// MARK: - LogAge

/// A type-safe representation of a time duration for log retention.
///
/// Use this instead of raw `TimeInterval` values to make log retention
/// configuration self-documenting:
/// ```swift
/// LoggerConfiguration(maxAge: .days(30))
/// LoggerConfiguration(maxAge: .weeks(2))
/// ```
public enum LogAge: Sendable, Equatable {
    case hours(Int)
    case days(Int)
    case weeks(Int)
    case months(Int)

    /// Converts to `TimeInterval` (seconds).
    public var timeInterval: TimeInterval {
        switch self {
        case .hours(let count):   return TimeInterval(count) * 3_600
        case .days(let count):    return TimeInterval(count) * 86_400
        case .weeks(let count):   return TimeInterval(count) * 604_800
        case .months(let count):  return TimeInterval(count) * 2_592_000 // 30-day months
        }
    }
}

// MARK: - StorageSize

/// A type-safe representation of a byte size for storage limits.
///
/// ```swift
/// LoggerConfiguration(maxTotalSize: .mb(50))
/// LoggerConfiguration(maxTotalSize: .gb(1))
/// ```
public enum StorageSize: Sendable, Equatable {
    case kb(Int)
    case mb(Int)
    case gb(Int)

    /// Converts to bytes (`Int64`).
    public var bytes: Int64 {
        switch self {
        case .kb(let count): return Int64(count) * 1_024
        case .mb(let count): return Int64(count) * 1_024 * 1_024
        case .gb(let count): return Int64(count) * 1_024 * 1_024 * 1_024
        }
    }
}

// MARK: - LoggerConfiguration

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
