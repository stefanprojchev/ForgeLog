#if os(iOS) || os(visionOS)
import Foundation
#if canImport(UIKit)
import UIKit
#endif

@Observable @MainActor
final class LogDetailViewModel {
    // MARK: - Input & State

    let input: LogDetailContent.Input
    var state: LogDetailContent.State

    // MARK: - Init

    init(input: LogDetailContent.Input) {
        self.input = input
        self.state = LogDetailContent.State(entry: input.entry)
    }

    // MARK: - Derived

    var currentEntry: LogEntry { state.currentEntry }

    /// Entries chronologically older than the current entry — oldest first.
    var contextBefore: [LogEntry] {
        let sorted = input.siblings.sorted { $0.timestamp < $1.timestamp }
        guard let idx = sorted.firstIndex(where: { $0.id == state.currentEntry.id }) else { return [] }
        let lower = max(0, idx - LogDetailContent.contextRadius)
        return Array(sorted[lower..<idx])
    }

    /// Entries chronologically newer than the current entry — oldest first.
    var contextAfter: [LogEntry] {
        let sorted = input.siblings.sorted { $0.timestamp < $1.timestamp }
        guard let idx = sorted.firstIndex(where: { $0.id == state.currentEntry.id }) else { return [] }
        let upper = min(sorted.count, idx + 1 + LogDetailContent.contextRadius)
        return Array(sorted[(idx + 1)..<upper])
    }

    var toastLabel: String? {
        guard let lastCopied = state.lastCopied else { return nil }
        switch lastCopied {
        case .message:        return LogDetailContent.toastMessageCopied
        case .fullEntry:      return LogDetailContent.toastEntryCopied
        case .meta(let key):  return LogDetailContent.toastMetaCopied(key)
        }
    }

    var markdown: String {
        var out = "**[\(state.currentEntry.level.displayName.uppercased())]** `\(state.currentEntry.formattedTime)` `\(state.currentEntry.moduleOrFallback)` `\(state.currentEntry.location)`\n\n\(state.currentEntry.message)"
        if let params = state.currentEntry.paramsMetadata, !params.isEmpty {
            out += "\n\n```\n"
            for (k, v) in params.sorted(by: { $0.key < $1.key }) {
                out += "\(k) = \(v.display)\n"
            }
            out += "```"
        }
        if let err = state.currentEntry.loggedError {
            out += "\n\n**Error:** \(err.domain) code \(err.code)\n> \(err.description)"
        }
        return out
    }

    // MARK: - Intents

    func navigateTo(_ entry: LogEntry) {
        state.currentEntry = entry
        state.lastCopied = nil
    }

    func copy(_ text: String, action: LogDetailContent.CopyAction) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
        state.lastCopied = action
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(1500))
            guard let self else { return }
            if self.state.lastCopied == action { self.state.lastCopied = nil }
        }
    }

    func runExport(format: LogExportFormat) {
        guard state.exportingFormat == nil else { return }
        state.exportingFormat = format
        let entry = state.currentEntry
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.state.exportingFormat = nil }
            do {
                let url = try await exporter.export([entry], format: format)
                let result = ExportResult(url: url, format: format, entryCount: 1)
                self.input.router.presentSheet(.exportResult(result))
            } catch {
                #if DEBUG
                print("[ForgeLog] Detail export failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Private

    @ObservationIgnored private let exporter = LogExporter()
}
#endif
