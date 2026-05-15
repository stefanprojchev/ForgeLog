import Foundation

/// A logging provider layer. Implementations receive log entries and handle them
/// in their own way (print, write to disk, send to remote server, etc.).
public protocol LogProviderProtocol: Sendable {
    /// A human-readable name for this provider.
    var name: String { get }

    /// The minimum log level this provider will handle.
    /// Entries below this level are skipped.
    var minimumLevel: LogLevel { get }

    /// Called by the logger to dispatch a log entry to this provider.
    func log(_ entry: LogEntry)
}
