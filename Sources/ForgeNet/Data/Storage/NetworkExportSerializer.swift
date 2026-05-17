#if os(iOS) || os(visionOS)
import Foundation
@_spi(ForgeLogPrimitives) import ForgeLog

/// Serializes a snapshot of `NetworkLogEntry` values in any of the
/// `LogExportFormat` outputs supported by `LogExporter`.
///
/// `LogExporter` itself works on `LogEntry`; this namespace produces text
/// that the same export primitive (`LogExporter.exportRaw`) writes to a
/// temp file with the right extension.
enum NetworkExportSerializer {
    // MARK: - Implementation

    static func text(for entries: [NetworkLogEntry], format: LogExportFormat) -> String {
        switch format {
        case .plainText: return entries.map(plainTextLine(_:)).joined(separator: "\n")
        case .markdown:  return markdown(entries)
        case .csv:       return csv(entries)
        case .json:      return json(entries, pretty: true)
        case .jsonl:     return json(entries, pretty: false)
        }
    }

    // MARK: - Private

    private static func plainTextLine(_ e: NetworkLogEntry) -> String {
        let status = e.status.map { "\($0)" } ?? "FAILED"
        return "\(e.formattedTime) \(e.method.rawValue) \(status) \(e.scheme)://\(e.host)\(e.path) · \(e.formattedDuration)"
    }

    private static func markdown(_ entries: [NetworkLogEntry]) -> String {
        var out = "# ForgeNet Export\n\n"
        out += "_Exported \(Date()) · \(entries.count) request\(entries.count == 1 ? "" : "s")_\n\n---\n\n"
        for e in entries {
            let status = e.status.map { "\($0)" } ?? "FAILED"
            out += "## \(e.method.rawValue) \(status) · `\(e.formattedTime)`\n\n"
            out += "**`\(e.scheme)://\(e.host)\(e.path)`**\n\n"
            out += "| | |\n|---|---|\n"
            out += "| Duration | `\(e.formattedDuration)` |\n"
            out += "| ↑ Request | `\(e.requestBytes)` B |\n"
            out += "| ↓ Response | `\(e.responseBytes)` B |\n"
            if let mod = e.callerModule { out += "| Caller | `\(mod)` |\n" }
            out += "\n---\n\n"
        }
        return out
    }

    private static func csv(_ entries: [NetworkLogEntry]) -> String {
        var out = "timestamp,method,status,scheme,host,path,duration_ms,request_bytes,response_bytes,mime,caller\n"
        for e in entries {
            let row = [
                ISO8601DateFormatter().string(from: e.timestamp),
                e.method.rawValue,
                e.status.map(String.init) ?? "FAILED",
                e.scheme,
                e.host,
                e.path,
                String(e.durationMs),
                String(e.requestBytes),
                String(e.responseBytes),
                e.mime,
                e.callerModule ?? "",
            ].map(csvField).joined(separator: ",")
            out += row + "\n"
        }
        return out
    }

    private static func csvField(_ raw: String) -> String {
        let needsQuoting = raw.contains(where: { ",\"\n\r".contains($0) })
        guard needsQuoting else { return raw }
        return "\"" + raw.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func json(_ entries: [NetworkLogEntry], pretty: Bool) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let data = try? encoder.encode(entries),
                  let str = String(data: data, encoding: .utf8) else { return "[]" }
            return str
        } else {
            encoder.outputFormatting = [.sortedKeys]
            var out = ""
            for e in entries {
                guard let data = try? encoder.encode(e),
                      let str = String(data: data, encoding: .utf8) else { continue }
                out += str + "\n"
            }
            return out
        }
    }
}

/// Reuses the log-side `LogExporter` to write raw text to a temp file —
/// shared between the network list (whole-session export) and the network
/// detail (single-request cURL export).
extension LogExporter {
    func exportRaw(text: String, fileName: String) async throws -> URL {
        let url = URL.temporaryDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
#endif
