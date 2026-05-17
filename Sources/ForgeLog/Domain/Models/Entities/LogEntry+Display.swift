import Foundation

extension LogEntry: Hashable {
    public static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
        lhs.id == rhs.id &&
        lhs.timestamp == rhs.timestamp &&
        lhs.level == rhs.level &&
        lhs.message == rhs.message &&
        lhs.className == rhs.className &&
        lhs.functionName == rhs.functionName &&
        lhs.line == rhs.line &&
        lhs.processes == rhs.processes &&
        lhs.module == rhs.module &&
        lhs.metadata == rhs.metadata
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension LogEntry {
    /// `15:29:38.044` — short time-only stamp for the row time column.
    var formattedTime: String {
        Self.shortTimeFormatter.string(from: timestamp)
    }

    /// `ClassName.function():142` style location string.
    var location: String {
        "\(className).\(functionName):\(line)"
    }

    /// True if non-nil/non-empty metadata exists.
    var hasAttachments: Bool { hasMetadata }

    /// Alias that matches the handoff vocabulary ("function" instead of "functionName").
    var function: String { functionName }

    /// Resolved module name, with a sensible fallback for entries logged from a
    /// file without a module prefix in `#fileID`.
    var moduleOrFallback: String { module ?? "Unknown" }

    private static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
