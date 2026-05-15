import Foundation
import ForgeCore

/// Writes log entries to JSONL files on disk, one file per day, under
/// `Application Support/Logs/`. Reads back by `LogStore`.
public struct DiskLogProvider: LogProviderProtocol {
    public let name: String = "DiskLogProvider"
    public let minimumLevel: LogLevel
    private let logDirectoryURL: URL
    private let queue: DispatchQueue
    private let encoder: JSONEncoder
    private let fileManager: FileManaging

    public init(
        minimumLevel: LogLevel = .debug,
        fileManager: FileManaging = SendableFileManager()
    ) {
        self.minimumLevel = minimumLevel
        self.fileManager = fileManager

        self.logDirectoryURL = URL.applicationSupportDirectory
            .appendingPathComponent("Logs", isDirectory: true)

        self.queue = DispatchQueue(label: "com.forgelog.DiskLogProvider", qos: .utility)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        try? fileManager.createDirectory(at: logDirectoryURL, withIntermediateDirectories: true)
    }

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        let directory = logDirectoryURL
        let fileManager = self.fileManager
        let encoder = self.encoder

        queue.async {
            Self.appendEntryToDisk(
                entry,
                directory: directory,
                fileManager: fileManager,
                encoder: encoder
            )
        }
    }

    private static func appendEntryToDisk(
        _ entry: LogEntry,
        directory: URL,
        fileManager: FileManaging,
        encoder: JSONEncoder
    ) {
        let fileName = Self.fileName(for: entry.timestamp)
        let fileURL = directory.appendingPathComponent(fileName)

        do {
            let entryData = try encoder.encode(entry)

            if fileManager.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: Data("\n".utf8))
                try handle.write(contentsOf: entryData)
            } else {
                try entryData.write(to: fileURL, options: .atomic)
            }
        } catch {
            // Fallback: cannot log via ForgeLog here — would recurse.
            print("[DiskLogProvider] Failed to write log entry: \(error.localizedDescription)")
        }
    }

    /// Generates the log file name for a given date: "logs-2026-03-02.jsonl"
    static func fileName(for date: Date) -> String {
        "logs-\(LogEntry.dayFormatter.string(from: date)).jsonl"
    }
}
