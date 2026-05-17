import Foundation
import ForgeCore

/// Reads, lists, and purges log files written by `DiskLogProvider` and `FileExportLogProvider`.
public struct LogStore: LogStoreProtocol {
    // MARK: - Dependencies

    private let logDirectoryURL: URL
    private let plainTextDirectoryURL: URL
    private let fileManager: FileManaging
    private let decoder: JSONDecoder

    // MARK: - Init

    public init(fileManager: FileManaging = SendableFileManager()) {
        self.fileManager = fileManager
        self.logDirectoryURL = URL.applicationSupportDirectory
            .appendingPathComponent("Logs", isDirectory: true)
        self.plainTextDirectoryURL = logDirectoryURL
            .appendingPathComponent("PlainText", isDirectory: true)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Implementation

    public func availableLogDates() async throws -> [Date] {
        guard fileManager.fileExists(atPath: logDirectoryURL.path) else {
            return []
        }

        let urls = try fileManager.contentsOfDirectory(
            at: logDirectoryURL,
            includingPropertiesForKeys: nil,
            options: []
        )

        return urls
            .map(\.lastPathComponent)
            .filter { $0.hasPrefix("logs-") && $0.hasSuffix(".jsonl") }
            .compactMap { fileName -> Date? in
                let dateString = fileName
                    .replacingOccurrences(of: "logs-", with: "")
                    .replacingOccurrences(of: ".jsonl", with: "")
                return LogEntry.dayFormatter.date(from: dateString)
            }
            .sorted(by: >)
    }

    public func loadEntries(for date: Date) async throws -> [LogEntry] {
        let fileName = DiskLogProvider.fileName(for: date)
        let fileURL = logDirectoryURL.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let lines = String(data: data, encoding: .utf8)?
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty } ?? []

        return lines.compactMap { line -> LogEntry? in
            guard let lineData = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(LogEntry.self, from: lineData)
        }
    }

    public func loadEntries(from startDate: Date, to endDate: Date) async throws -> [LogEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: min(startDate, endDate))
        let end = calendar.startOfDay(for: max(startDate, endDate))

        var allEntries: [LogEntry] = []
        var current = start

        while current <= end {
            let dayEntries = try await loadEntries(for: current)
            allEntries.append(contentsOf: dayEntries)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return allEntries.sorted { $0.timestamp < $1.timestamp }
    }

    public func purge(olderThan interval: TimeInterval) async throws {
        try await purge(maxAge: interval, maxTotalSize: nil)
    }

    public func purge(maxAge: TimeInterval?, maxTotalSize: Int64?) async throws {
        guard maxAge != nil || maxTotalSize != nil else { return }

        let dates = try await availableLogDates() // most recent first
        let sortedOldestFirst = dates.sorted()

        // Phase 1: Age-based purge.
        if let maxAge {
            let cutoffDate = Date().addingTimeInterval(-maxAge)
            for date in sortedOldestFirst where date < cutoffDate {
                deleteLogFiles(for: date)
            }
        }

        // Phase 2: Size-based purge. Recalculate remaining files after age purge.
        if let maxTotalSize {
            let remainingDates = (try await availableLogDates()).sorted()
            var totalSize = try await totalDiskUsage()

            for date in remainingDates {
                guard totalSize > maxTotalSize else { break }
                let fileSize = self.fileSize(for: date)
                deleteLogFiles(for: date)
                totalSize -= fileSize
            }
        }
    }

    public func logFileURL(for date: Date) -> URL? {
        let fileURL = logDirectoryURL.appendingPathComponent(DiskLogProvider.fileName(for: date))
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    public func deleteLog(for date: Date) async throws {
        deleteLogFiles(for: date)
    }

    public func deleteAllLogs() async throws {
        guard fileManager.fileExists(atPath: logDirectoryURL.path) else { return }

        // JSONL files
        let jsonlURLs = (try? fileManager.contentsOfDirectory(
            at: logDirectoryURL,
            includingPropertiesForKeys: nil,
            options: []
        )) ?? []
        for url in jsonlURLs where url.lastPathComponent.hasPrefix("logs-") && url.lastPathComponent.hasSuffix(".jsonl") {
            try? fileManager.removeItem(at: url)
        }

        // Plain text files
        if fileManager.fileExists(atPath: plainTextDirectoryURL.path) {
            let txtURLs = (try? fileManager.contentsOfDirectory(
                at: plainTextDirectoryURL,
                includingPropertiesForKeys: nil,
                options: []
            )) ?? []
            for url in txtURLs where url.lastPathComponent.hasPrefix("logs-") && url.lastPathComponent.hasSuffix(".txt") {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    public func totalDiskUsage() async throws -> Int64 {
        guard fileManager.fileExists(atPath: logDirectoryURL.path) else { return 0 }

        var totalSize: Int64 = 0

        let jsonlURLs = (try? fileManager.contentsOfDirectory(
            at: logDirectoryURL,
            includingPropertiesForKeys: nil,
            options: []
        )) ?? []
        for url in jsonlURLs where url.lastPathComponent.hasPrefix("logs-") && url.lastPathComponent.hasSuffix(".jsonl") {
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                totalSize += size
            }
        }

        if fileManager.fileExists(atPath: plainTextDirectoryURL.path) {
            let txtURLs = (try? fileManager.contentsOfDirectory(
                at: plainTextDirectoryURL,
                includingPropertiesForKeys: nil,
                options: []
            )) ?? []
            for url in txtURLs where url.lastPathComponent.hasPrefix("logs-") && url.lastPathComponent.hasSuffix(".txt") {
                if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? Int64 {
                    totalSize += size
                }
            }
        }

        return totalSize
    }

    // MARK: - Private

    /// Deletes both JSONL and plain text log files for a given date.
    private func deleteLogFiles(for date: Date) {
        let jsonlURL = logDirectoryURL.appendingPathComponent(DiskLogProvider.fileName(for: date))
        try? fileManager.removeItem(at: jsonlURL)

        let txtURL = plainTextDirectoryURL.appendingPathComponent(FileExportLogProvider.fileName(for: date))
        try? fileManager.removeItem(at: txtURL)
    }

    /// Returns the combined file size of JSONL and plain text log files for a given date.
    private func fileSize(for date: Date) -> Int64 {
        var total: Int64 = 0

        let jsonlURL = logDirectoryURL.appendingPathComponent(DiskLogProvider.fileName(for: date))
        if let attrs = try? fileManager.attributesOfItem(atPath: jsonlURL.path),
           let size = attrs[.size] as? Int64 {
            total += size
        }

        let txtURL = plainTextDirectoryURL.appendingPathComponent(FileExportLogProvider.fileName(for: date))
        if let attrs = try? fileManager.attributesOfItem(atPath: txtURL.path),
           let size = attrs[.size] as? Int64 {
            total += size
        }

        return total
    }
}
