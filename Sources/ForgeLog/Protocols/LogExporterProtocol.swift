import Foundation

/// Supported export formats for log data.
public enum LogExportFormat: String, Sendable, CaseIterable, Identifiable, Hashable {
    /// Human-readable lines, one entry per line. Same shape as
    /// `LogEntry.plainTextMessage`. Best for sharing with QA or attaching to
    /// support tickets.
    case plainText
    /// GitHub-flavored Markdown. Each entry becomes a small block with a
    /// header line + metadata table + optional code fence for params and a
    /// quote block for the error. Renders nicely in chat or issue trackers.
    case markdown
    /// Comma-separated values with a header row. Fields containing commas,
    /// quotes, or newlines are quoted and escaped per RFC 4180. Easy to open
    /// in Numbers or Excel.
    case csv
    /// Pretty-printed JSON array of entries. Best for round-tripping back
    /// through `JSONDecoder` or for debugging tools.
    case json
    /// Newline-delimited JSON — one compact JSON entry per line. The
    /// canonical streaming format for log shippers and log search engines
    /// (Splunk, Elastic, Loki, …).
    case jsonl

    public var id: String { rawValue }

    /// Lowercase file extension without leading dot.
    public var fileExtension: String {
        switch self {
        case .plainText: return "txt"
        case .markdown:  return "md"
        case .csv:       return "csv"
        case .json:      return "json"
        case .jsonl:     return "jsonl"
        }
    }

    /// Display name used in menus / share sheets.
    public var displayName: String {
        switch self {
        case .plainText: return "Plain Text"
        case .markdown:  return "Markdown"
        case .csv:       return "CSV"
        case .json:      return "JSON"
        case .jsonl:     return "JSON Lines (NDJSON)"
        }
    }

    /// SF Symbol name to render alongside the menu row.
    public var iconName: String {
        switch self {
        case .plainText: return "doc.plaintext"
        case .markdown:  return "text.alignleft"
        case .csv:       return "tablecells"
        case .json:      return "curlybraces"
        case .jsonl:     return "list.bullet.indent"
        }
    }

    /// One-line hint shown below the format name in the menu.
    public var subtitle: String {
        switch self {
        case .plainText: return "Readable .txt"
        case .markdown:  return "Paste-into-chat .md"
        case .csv:       return "Open in Numbers / Excel"
        case .json:      return "Pretty JSON array"
        case .jsonl:     return "Stream-friendly NDJSON"
        }
    }
}

/// Protocol for exporting log entries to files.
public protocol LogExporterProtocol: Sendable {
    /// Exports the given log entries to a temporary file in the specified format.
    func export(_ entries: [LogEntry], format: LogExportFormat) async throws -> URL
}
