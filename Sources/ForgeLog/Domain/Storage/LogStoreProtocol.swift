import Foundation

/// Protocol for managing log file storage on disk.
public protocol LogStoreProtocol: Sendable {
    /// Returns a list of available log file dates (one per day), most recent first.
    func availableLogDates() async throws -> [Date]

    /// Loads all log entries for a specific date.
    func loadEntries(for date: Date) async throws -> [LogEntry]

    /// Loads log entries across a date range (inclusive on both ends).
    func loadEntries(from startDate: Date, to endDate: Date) async throws -> [LogEntry]

    /// Purges log files older than the specified interval.
    func purge(olderThan interval: TimeInterval) async throws

    /// Purges log files based on age and/or total size limits.
    ///
    /// Both constraints are applied — whichever is reached first triggers deletion.
    /// Oldest files are always deleted first.
    func purge(maxAge: TimeInterval?, maxTotalSize: Int64?) async throws

    /// Returns the file URL for logs of a specific date (for sharing/export).
    func logFileURL(for date: Date) -> URL?

    /// Deletes the log file for a specific date.
    func deleteLog(for date: Date) async throws

    /// Deletes all log files.
    func deleteAllLogs() async throws

    /// Returns the total size of all log files in bytes.
    func totalDiskUsage() async throws -> Int64
}
