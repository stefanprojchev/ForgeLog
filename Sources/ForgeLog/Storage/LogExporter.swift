import Foundation
import ForgeCore

/// Exports log entries to temporary files in any of `LogExportFormat`'s cases,
/// ready to be shared via the system share sheet or attached to a support ticket.
public struct LogExporter: LogExporterProtocol {
    private let fileManager: FileManaging

    public init(fileManager: FileManaging = SendableFileManager()) {
        self.fileManager = fileManager
    }

    public func export(_ entries: [LogEntry], format: LogExportFormat) async throws -> URL {
        cleanUpPreviousExports()

        switch format {
        case .plainText: return try exportAsPlainText(entries)
        case .markdown:  return try exportAsMarkdown(entries)
        case .csv:       return try exportAsCSV(entries)
        case .json:      return try exportAsJSON(entries)
        case .jsonl:     return try exportAsJSONL(entries)
        }
    }

    // MARK: - Cleanup

    private func cleanUpPreviousExports() {
        let tempDir = URL.temporaryDirectory
        for format in LogExportFormat.allCases {
            let url = tempDir.appendingPathComponent("logs-export.\(format.fileExtension)")
            try? fileManager.removeItem(at: url)
        }
    }

    private func tempURL(for format: LogExportFormat) -> URL {
        URL.temporaryDirectory.appendingPathComponent("logs-export.\(format.fileExtension)")
    }

    // MARK: - Plain text

    private func exportAsPlainText(_ entries: [LogEntry]) throws -> URL {
        let text = entries.map(\.plainTextMessage).joined(separator: "\n")
        let url = tempURL(for: .plainText)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Markdown

    private func exportAsMarkdown(_ entries: [LogEntry]) throws -> URL {
        var out = ""
        out += "# ForgeLog Export\n\n"
        let exported = LogEntry.timestampFormatter.string(from: Date())
        out += "_Exported \(exported) · \(entries.count) entr\(entries.count == 1 ? "y" : "ies")_\n\n"
        out += "---\n\n"

        for entry in entries {
            let level = entry.level.label.uppercased()
            let ts = LogEntry.timestampFormatter.string(from: entry.timestamp)
            let module = entry.module ?? "—"
            out += "## \(entry.level.emoji) \(level) · `\(ts)`\n\n"
            out += "**\(entry.message)**\n\n"
            out += "| | |\n|---|---|\n"
            out += "| Module | `\(module)` |\n"
            out += "| Location | `\(entry.className).\(entry.functionName):\(entry.line)` |\n"
            if !entry.processes.isEmpty {
                let procs = entry.processes.map { "`\($0)`" }.joined(separator: ", ")
                out += "| Processes | \(procs) |\n"
            }
            if let metadata = entry.metadata, !metadata.isEmpty {
                out += "\n```\n"
                for key in metadata.keys.sorted() {
                    out += "\(key) = \(metadata[key]!.description)\n"
                }
                out += "```\n"
            }
            out += "\n---\n\n"
        }

        let url = tempURL(for: .markdown)
        try out.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - CSV

    private func exportAsCSV(_ entries: [LogEntry]) throws -> URL {
        var out = "timestamp,level,module,class,function,line,processes,message,metadata\n"
        for entry in entries {
            let ts = Self.iso8601(entry.timestamp)
            let processes = entry.processes.joined(separator: "; ")
            let metadata = entry.metadata.map { AnyCodableValue.plainText(from: $0) } ?? ""
            let row = [
                ts,
                entry.level.label,
                entry.module ?? "",
                entry.className,
                entry.functionName,
                String(entry.line),
                processes,
                entry.message,
                metadata,
            ].map(Self.csvField).joined(separator: ",")
            out += row + "\n"
        }

        let url = tempURL(for: .csv)
        try out.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// RFC 4180 field quoting. Wrap in quotes if the field contains `,`,
    /// `"`, `\n`, or `\r`. Inner quotes are doubled.
    private static func csvField(_ raw: String) -> String {
        let needsQuoting = raw.contains(where: { ",\"\n\r".contains($0) })
        guard needsQuoting else { return raw }
        let escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    // MARK: - JSON

    private func exportAsJSON(_ entries: [LogEntry]) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(entries)
        let url = tempURL(for: .json)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - JSON Lines / NDJSON

    private func exportAsJSONL(_ entries: [LogEntry]) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        var data = Data()
        let newline = Data("\n".utf8)
        for entry in entries {
            let entryData = try encoder.encode(entry)
            data.append(entryData)
            data.append(newline)
        }

        let url = tempURL(for: .jsonl)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Formatters

    /// `ISO8601DateFormatter` is not `Sendable` in Swift 6 strict mode, so we
    /// build a fresh one per call. Cheap to instantiate; the alternative is
    /// burning a `nonisolated(unsafe)` annotation for negligible gain.
    private static func iso8601(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }
}
