import Foundation
import os

/// Forwards log entries to Apple's unified logging system (`os.Logger`).
/// Visible in Console.app and via the `log` command-line tool.
public struct ConsoleLogProvider: LogProviderProtocol {
    public let name: String = "ConsoleLogProvider"
    public let minimumLevel: LogLevel
    private let osLogger: os.Logger

    /// - Parameters:
    ///   - subsystem: The subsystem for `os.Logger` (typically `Bundle.main.bundleIdentifier`).
    ///   - category: The category for `os.Logger`.
    ///   - minimumLevel: Minimum log level to process.
    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.forgelog",
        category: String = "ForgeLog",
        minimumLevel: LogLevel = .debug
    ) {
        self.minimumLevel = minimumLevel
        self.osLogger = os.Logger(subsystem: subsystem, category: category)
    }

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        let message = entry.formattedMessage

        switch entry.level {
        case .debug:
            osLogger.debug("\(message, privacy: .public)")
        case .info:
            osLogger.info("\(message, privacy: .public)")
        case .warning:
            osLogger.warning("\(message, privacy: .public)")
        case .error:
            osLogger.error("\(message, privacy: .public)")
        }
    }
}
