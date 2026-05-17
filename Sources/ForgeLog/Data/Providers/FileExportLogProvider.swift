import Foundation
import ForgeCore

/// Writes plain text log files to disk for direct sharing with QA or support.
/// Unlike `DiskLogProvider` (JSONL for structured parsing), this writes
/// human-readable text files. No export/conversion step required.
///
/// Files are named `logs-YYYY-MM-DD.txt` and stored in
/// `Application Support/Logs/PlainText/`.
public struct FileExportLogProvider: LogProviderProtocol {
    // MARK: - Dependencies

    public let name: String = "FileExportLogProvider"
    public let minimumLevel: LogLevel
    private let logDirectoryURL: URL
    private let queue: DispatchQueue
    private let fileManager: FileManaging

    // MARK: - Init

    public init(
        minimumLevel: LogLevel = .debug,
        fileManager: FileManaging = SendableFileManager()
    ) {
        self.minimumLevel = minimumLevel
        self.fileManager = fileManager

        self.logDirectoryURL = URL.applicationSupportDirectory
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("PlainText", isDirectory: true)

        self.queue = DispatchQueue(label: "com.forgelog.FileExportLogProvider", qos: .utility)

        try? fileManager.createDirectory(at: logDirectoryURL, withIntermediateDirectories: true)
    }

    // MARK: - Implementation

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        let directory = logDirectoryURL
        let fileManager = self.fileManager

        queue.async {
            Self.appendEntryToDisk(entry, directory: directory, fileManager: fileManager)
        }
    }

    /// Returns the URL for today's plain text log file, if it exists.
    public func todaysLogFileURL() -> URL? {
        let fileURL = logDirectoryURL.appendingPathComponent(Self.fileName(for: Date()))
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    /// Returns URLs for all available plain text log files, most recent first.
    public func availableLogFileURLs() -> [URL] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: logDirectoryURL,
            includingPropertiesForKeys: nil,
            options: []
        ) else {
            return []
        }

        return urls
            .filter { $0.lastPathComponent.hasPrefix("logs-") && $0.lastPathComponent.hasSuffix(".txt") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    // MARK: - Private

    private static func appendEntryToDisk(
        _ entry: LogEntry,
        directory: URL,
        fileManager: FileManaging
    ) {
        let fileName = Self.fileName(for: entry.timestamp)
        let fileURL = directory.appendingPathComponent(fileName)
        let line = entry.plainTextMessage + "\n"

        guard let lineData = line.data(using: .utf8) else { return }

        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: lineData)
            } else {
                try lineData.write(to: fileURL, options: .atomic)
            }
        } catch {
            print("[FileExportLogProvider] Failed to write log entry: \(error.localizedDescription)")
        }
    }

    static func fileName(for date: Date) -> String {
        "logs-\(LogEntry.dayFormatter.string(from: date)).txt"
    }
}
