#if os(iOS) || os(visionOS)
import Foundation
@_spi(ForgeLogPrimitives) import ForgeLog

enum NetworkDetailContent {
    // MARK: - Static

    static let navTitle = "Request"

    // MARK: - Input & State

    struct Input {
        let router: ForgeNetFlowRouter
        let entry: NetworkLogEntry
    }

    struct State {
        var tab: Tab = .overview
        var bodyMode: BodyMode = .pretty
        var exportingFormat: LogExportFormat?

        static let `default` = State()
    }

    // MARK: - Types

    enum Tab: String, CaseIterable, Identifiable {
        case overview, request, response, timing
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    enum BodyMode {
        case pretty, raw, preview
    }
}
#endif
