#if os(iOS) || os(visionOS)
import Foundation

@Observable @MainActor
final class LogListViewModel {
    // MARK: - Input & State

    let input: LogListContent.Input
    var state = LogListContent.State.default

    // MARK: - Init

    init(input: LogListContent.Input) {
        self.input = input
    }

    // MARK: - Derived

    var buffer: LiveLogBuffer { input.buffer }
    var router: ForgeLogFlowRouter { input.router }

    /// Entries that pass the current filter, ordered newest-first.
    var filteredEntries: [LogEntry] {
        buffer.entries.reversed().filter(state.filter.matches)
    }

    var levelCounts: LevelCounts {
        LevelCounts.compute(from: buffer.entries)
    }

    var hasActiveFiltersBeyondLevel: Bool {
        state.filter.hasActiveFilters
    }

    var hasActiveFilters: Bool {
        state.filter.hasActiveFilters || state.filter.level != nil
    }

    // MARK: - Intents

    func clearFilters() {
        state.filter.clear()
    }

    func clearChipFilters() {
        state.filter.clearChipFilters()
    }

    func setLevel(_ level: LogLevel?) {
        state.filter.level = level
    }

    func toggleExpanded(_ id: LogEntry.ID) {
        state.expandedID = state.expandedID == id ? nil : id
    }

    func setExpanded(_ id: LogEntry.ID?) {
        state.expandedID = id
    }

    func openSettings() {
        router.push(.settings)
    }

    func openConcepts() {
        router.presentSheet(.concepts)
    }

    func openDetail(_ entry: LogEntry) {
        router.presentSheet(.detail(entry: entry, siblings: filteredEntries))
    }

    func openModuleFilter() {
        router.presentSheet(.filterPicker(
            kind: .module,
            current: state.filter.modules,
            onApply: { [weak self] selection in
                self?.state.filter.modules = selection
            }
        ))
    }

    func openProcessFilter() {
        router.presentSheet(.filterPicker(
            kind: .process,
            current: state.filter.processes,
            onApply: { [weak self] selection in
                self?.state.filter.processes = selection
            }
        ))
    }

    func openClassFilter() {
        router.presentSheet(.filterPicker(
            kind: .klass,
            current: state.filter.classes,
            onApply: { [weak self] selection in
                self?.state.filter.classes = selection
            }
        ))
    }

    func openDateRange() {
        router.presentSheet(.dateRange(
            initialRange: state.filter.dateRange,
            entries: buffer.entries,
            onApply: { [weak self] range in
                self?.state.filter.dateRange = range
            }
        ))
    }

    func runExport(format: LogExportFormat) {
        guard state.exportingFormat == nil else { return }
        let snapshot = filteredEntries
        guard !snapshot.isEmpty else { return }
        state.exportingFormat = format
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.state.exportingFormat = nil }
            do {
                let url = try await exporter.export(snapshot, format: format)
                let result = ExportResult(url: url, format: format, entryCount: snapshot.count)
                self.router.presentSheet(.exportResult(result))
            } catch {
                #if DEBUG
                print("[ForgeLog] Export failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Private

    @ObservationIgnored private let exporter = LogExporter()
}
#endif
