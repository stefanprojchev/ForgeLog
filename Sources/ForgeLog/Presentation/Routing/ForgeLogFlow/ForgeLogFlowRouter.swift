#if os(iOS) || os(visionOS)
import Foundation
import SwiftUI

@Observable @MainActor
public final class ForgeLogFlowRouter: FlowRouting {
    // MARK: - Routes

    public var path: [Route] = []

    public enum Route: Hashable {
        case settings
    }

    // MARK: - Sheets

    var presentedSheet: Sheet?

    enum Sheet: Identifiable {
        case detail(entry: LogEntry, siblings: [LogEntry])
        case filterPicker(kind: FilterPickerContent.Kind, current: Set<String>, onApply: @MainActor (Set<String>) -> Void)
        case dateRange(initialRange: ClosedRange<Date>?, entries: [LogEntry], onApply: @MainActor (ClosedRange<Date>?) -> Void)
        case concepts
        case exportResult(ExportResult)

        var id: String {
            switch self {
            case .detail(let entry, _):           return "detail-\(entry.id)"
            case .filterPicker(let kind, _, _):   return "filter-\(kind.rawValue)"
            case .dateRange:                       return "date"
            case .concepts:                        return "concepts"
            case .exportResult(let result):       return "export-\(result.url.lastPathComponent)"
            }
        }
    }

    // MARK: - Dependencies

    let buffer: LiveLogBuffer

    // MARK: - Init

    public init(buffer: LiveLogBuffer = LiveLogBuffer()) {
        self.buffer = buffer
    }

    // MARK: - Sheet Presentation

    func presentSheet(_ sheet: Sheet) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    // MARK: - View Model Factories

    func makeLogListVM() -> LogListViewModel {
        LogListViewModel(input: .init(router: self, buffer: buffer))
    }

    func makeSettingsVM() -> SettingsViewModel {
        SettingsViewModel(input: .init(buffer: buffer))
    }

    func makeLogDetailVM(entry: LogEntry, siblings: [LogEntry]) -> LogDetailViewModel {
        LogDetailViewModel(input: .init(router: self, entry: entry, siblings: siblings))
    }

    func makeFilterPickerVM(
        kind: FilterPickerContent.Kind,
        current: Set<String>,
        onApply: @escaping @MainActor (Set<String>) -> Void
    ) -> FilterPickerViewModel {
        FilterPickerViewModel(input: .init(
            router: self,
            kind: kind,
            initialSelection: current,
            buffer: buffer,
            onApply: onApply
        ))
    }

    func makeDateRangePickerVM(
        initialRange: ClosedRange<Date>?,
        entries: [LogEntry],
        onApply: @escaping @MainActor (ClosedRange<Date>?) -> Void
    ) -> DateRangePickerViewModel {
        DateRangePickerViewModel(input: .init(
            router: self,
            initialRange: initialRange,
            entries: entries,
            onApply: onApply
        ))
    }

    func makeLogConceptsVM() -> LogConceptsViewModel {
        LogConceptsViewModel(input: .init(router: self))
    }
}
#endif
