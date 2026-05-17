import Foundation

public struct LogEntry: Codable, Sendable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let className: String
    public let functionName: String
    public let line: Int
    public let processes: [String]
    public let module: String?
    public let metadata: [String: AnyCodableValue]?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        className: String,
        functionName: String,
        line: Int,
        processes: [String] = [],
        module: String? = nil,
        metadata: [String: AnyCodableValue]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.className = className
        self.functionName = functionName
        self.line = line
        self.processes = processes
        self.module = module
        self.metadata = metadata
    }

    /// Formatted string for print/console output (includes emoji).
    public var formattedMessage: String {
        formatMessage(includeEmoji: true)
    }

    /// Plain text format (no emoji) for .txt export.
    public var plainTextMessage: String {
        formatMessage(includeEmoji: false)
    }

    /// Whether this entry has non-empty metadata attached.
    public var hasMetadata: Bool {
        guard let metadata else { return false }
        return !metadata.isEmpty
    }

    /// Timestamp formatter for log output: "2026-03-02 14:30:05.123"
    static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Day-only formatter for log file names: "2026-03-02"
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private func formatMessage(includeEmoji: Bool) -> String {
        let ts = Self.timestampFormatter.string(from: timestamp)
        let levelPrefix = includeEmoji ? "\(level.emoji) \(level.label)" : level.label
        let processTag = processes.isEmpty ? "" : " [\(processes.joined(separator: ", "))]"
        let moduleTag = module.map { " (\($0))" } ?? ""
        var result = "\(ts) \(levelPrefix)\(processTag)\(moduleTag) [\(className).\(functionName):\(line)] \(message)"
        if let metadata, !metadata.isEmpty {
            result += " | \(AnyCodableValue.plainText(from: metadata))"
        }
        return result
    }
}
