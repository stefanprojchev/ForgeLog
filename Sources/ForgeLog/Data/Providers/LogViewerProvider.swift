#if os(iOS) || os(visionOS)
import Foundation

/// A provider that forwards every entry it receives to a `@Sendable` closure.
/// Used by `LogViewerStore` to subscribe to `ForgeLog`'s pipeline — register
/// this once at app startup and the viewer stays live.
public struct LogViewerProvider: LogProviderProtocol {
    public let name: String = "LogViewerProvider"
    public let minimumLevel: LogLevel
    private let onEntry: @Sendable (LogEntry) -> Void

    public init(
        minimumLevel: LogLevel = .debug,
        onEntry: @escaping @Sendable (LogEntry) -> Void
    ) {
        self.minimumLevel = minimumLevel
        self.onEntry = onEntry
    }

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }
        onEntry(entry)
    }
}
#endif
