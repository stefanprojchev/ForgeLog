#if os(iOS) || os(visionOS)
import Foundation
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

@Observable @MainActor
public final class ForgeNetFlowRouter: FlowRouting {
    // MARK: - Routes

    public var path: [Route] = []

    public enum Route: Hashable {
        case settings
    }

    // MARK: - Sheets

    var presentedSheet: Sheet?

    enum Sheet: Identifiable {
        case detail(entry: NetworkLogEntry)
        case filterPicker(kind: NetworkFilterPickerContent.Kind, current: Set<String>, onApply: @MainActor (Set<String>) -> Void)
        case concepts
        case exportResult(ExportResult)

        var id: String {
            switch self {
            case .detail(let entry):              return "detail-\(entry.id)"
            case .filterPicker(let kind, _, _):   return "filter-\(kind.rawValue)"
            case .concepts:                       return "concepts"
            case .exportResult(let result):       return "export-\(result.url.lastPathComponent)"
            }
        }
    }

    // MARK: - Dependencies

    let buffer: NetworkLogBuffer

    // MARK: - Init

    public init(buffer: NetworkLogBuffer) {
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

    func makeNetworkListVM() -> NetworkListViewModel {
        NetworkListViewModel(input: .init(router: self, buffer: buffer))
    }

    func makeNetworkSettingsVM() -> NetworkSettingsViewModel {
        NetworkSettingsViewModel(input: .init(buffer: buffer))
    }

    func makeNetworkDetailVM(entry: NetworkLogEntry) -> NetworkDetailViewModel {
        NetworkDetailViewModel(input: .init(router: self, entry: entry))
    }

    func makeNetworkFilterPickerVM(
        kind: NetworkFilterPickerContent.Kind,
        current: Set<String>,
        onApply: @escaping @MainActor (Set<String>) -> Void
    ) -> NetworkFilterPickerViewModel {
        NetworkFilterPickerViewModel(input: .init(
            router: self,
            kind: kind,
            initialSelection: current,
            buffer: buffer,
            onApply: onApply
        ))
    }

    func makeNetworkConceptsVM() -> NetworkConceptsViewModel {
        NetworkConceptsViewModel(input: .init(router: self))
    }
}
#endif
