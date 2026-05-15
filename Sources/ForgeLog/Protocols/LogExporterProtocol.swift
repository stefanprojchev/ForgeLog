import Foundation

/// Supported export formats for log data.
public enum LogExportFormat: Sendable {
    case plainText
    case json
}

/// Protocol for exporting log entries to files.
public protocol LogExporterProtocol: Sendable {
    /// Exports the given log entries to a temporary file in the specified format.
    func export(_ entries: [LogEntry], format: LogExportFormat) async throws -> URL
}
