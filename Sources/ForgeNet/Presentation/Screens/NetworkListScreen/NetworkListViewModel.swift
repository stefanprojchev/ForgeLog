#if os(iOS) || os(visionOS)
import Foundation
@_spi(ForgeLogPrimitives) import ForgeLog

@Observable @MainActor
final class NetworkListViewModel {
    // MARK: - Input & State

    let input: NetworkListContent.Input
    var state = NetworkListContent.State.default

    // MARK: - Init

    init(input: NetworkListContent.Input) {
        self.input = input
    }

    // MARK: - Derived

    var buffer: NetworkLogBuffer { input.buffer }
    var router: ForgeNetFlowRouter { input.router }

    var filteredEntries: [NetworkLogEntry] {
        buffer.entries.reversed().filter(state.filter.matches)
    }

    var statusFamilyCounts: StatusFamilyCounts {
        StatusFamilyCounts.compute(from: buffer.entries)
    }

    var hasActiveFilters: Bool {
        state.filter.hasActiveFilters || state.filter.statusFamily != nil
    }

    // MARK: - Intents

    func clearFilters() {
        state.filter.clear()
    }

    func setStatusFamily(_ family: HTTPStatusFamily?) {
        state.filter.statusFamily = family
    }

    func openSettings() {
        router.push(.settings)
    }

    func openConcepts() {
        router.presentSheet(.concepts)
    }

    func openDetail(_ entry: NetworkLogEntry) {
        router.presentSheet(.detail(entry: entry))
    }

    func openMethodFilter() {
        router.presentSheet(.filterPicker(
            kind: .method,
            current: Set(state.filter.methods.map(\.rawValue)),
            onApply: { [weak self] selection in
                self?.state.filter.methods = Set(selection.compactMap(HTTPMethod.init(rawValue:)))
            }
        ))
    }

    func openHostFilter() {
        router.presentSheet(.filterPicker(
            kind: .host,
            current: state.filter.hosts,
            onApply: { [weak self] selection in
                self?.state.filter.hosts = selection
            }
        ))
    }

    func openCallerFilter() {
        router.presentSheet(.filterPicker(
            kind: .caller,
            current: state.filter.callers,
            onApply: { [weak self] selection in
                self?.state.filter.callers = selection
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
                let url = try await exporter.exportRaw(
                    text: NetworkExportSerializer.text(for: snapshot, format: format),
                    fileName: "network-export.\(format.fileExtension)"
                )
                let result = ExportResult(url: url, format: format, entryCount: snapshot.count)
                self.router.presentSheet(.exportResult(result))
            } catch {
                #if DEBUG
                print("[ForgeNet] Export failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Private

    @ObservationIgnored private let exporter = LogExporter()
}
#endif
