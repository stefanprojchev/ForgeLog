import Foundation

/// Forwards log entries to Swift `print()` (Xcode console).
public struct PrintLogProvider: LogProviderProtocol {
    public let name: String = "PrintLogProvider"
    public let minimumLevel: LogLevel

    public init(minimumLevel: LogLevel = .debug) {
        self.minimumLevel = minimumLevel
    }

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }
        print(entry.formattedMessage)
    }
}
