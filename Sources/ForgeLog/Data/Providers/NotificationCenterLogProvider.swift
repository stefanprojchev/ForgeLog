import Foundation

/// Posts an `NSNotification` for each log entry. Useful for in-app debug
/// overlays or reactive UI that listens for log events without coupling to
/// the logger.
///
/// ```swift
/// NotificationCenter.default.addObserver(
///     forName: NotificationCenterLogProvider.logEntryNotification,
///     object: nil,
///     queue: .main
/// ) { notification in
///     if let entry = notification.userInfo?[NotificationCenterLogProvider.logEntryKey] as? LogEntry {
///         // Update debug overlay
///     }
/// }
/// ```
public struct NotificationCenterLogProvider: LogProviderProtocol {
    // MARK: - Static

    /// Notification name posted for each log entry.
    public static let logEntryNotification = Notification.Name("com.forgelog.LogEntryNotification")

    /// Key in `userInfo` dictionary containing the `LogEntry`.
    public static let logEntryKey = "logEntry"

    // MARK: - Dependencies

    public let name: String = "NotificationCenterLogProvider"
    public let minimumLevel: LogLevel
    private let notificationCenter: NotificationCenter

    // MARK: - Init

    public init(
        minimumLevel: LogLevel = .debug,
        notificationCenter: NotificationCenter = .default
    ) {
        self.minimumLevel = minimumLevel
        self.notificationCenter = notificationCenter
    }

    // MARK: - Implementation

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        notificationCenter.post(
            name: Self.logEntryNotification,
            object: nil,
            userInfo: [Self.logEntryKey: entry]
        )
    }
}
