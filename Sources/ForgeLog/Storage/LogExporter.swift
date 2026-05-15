import Foundation
import ForgeCore

/// Exports log entries to temporary files in plain text or JSON format,
/// ready to be shared via the system share sheet or attached to a support ticket.
public struct LogExporter: LogExporterProtocol {
    private let fileManager: FileManaging

    public init(fileManager: FileManaging = SendableFileManager()) {
        self.fileManager = fileManager
    }

    public func export(_ entries: [LogEntry], format: LogExportFormat) async throws -> URL {
        cleanUpPreviousExports()

        switch format {
        case .plainText:
            return try exportAsPlainText(entries)
        case .json:
            return try exportAsJSON(entries)
        }
    }

    // MARK: - Private

    /// File names used for exports. Cleaned up before each new export.
    private static let exportFileNames = ["logs-export.txt", "logs-export.json"]

    private func cleanUpPreviousExports() {
        let tempDir = URL.temporaryDirectory
        for name in Self.exportFileNames {
            let url = tempDir.appendingPathComponent(name)
            try? fileManager.removeItem(at: url)
        }
    }

    private func exportAsPlainText(_ entries: [LogEntry]) throws -> URL {
        let text = entries.map(\.plainTextMessage).joined(separator: "\n")
        let url = URL.temporaryDirectory.appendingPathComponent("logs-export.txt")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func exportAsJSON(_ entries: [LogEntry]) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(entries)
        let url = URL.temporaryDirectory.appendingPathComponent("logs-export.json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
