#if os(iOS) || os(visionOS)
import Foundation
@_spi(ForgeLogPrimitives) import ForgeLog

enum NetworkListContent {
    // MARK: - Static

    static let navTitle = "Network"
    static let viewerTitle = "Network Viewer"
    static let searchPlaceholder = "Search URL, host, class…"

    static func exportSubtitle(filteredCount: Int) -> String {
        "Export \(filteredCount) filtered request\(filteredCount == 1 ? "" : "s")"
    }

    // MARK: - Input & State

    struct Input {
        let router: ForgeNetFlowRouter
        let buffer: NetworkLogBuffer
    }

    struct State {
        var filter: NetworkFilterState = NetworkFilterState()
        var exportingFormat: LogExportFormat?

        static let `default` = State()
    }
}
#endif
