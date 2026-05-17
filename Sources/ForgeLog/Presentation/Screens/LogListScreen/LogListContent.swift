#if os(iOS) || os(visionOS)
import Foundation

enum LogListContent {
    // MARK: - Static

    static let navTitle = "Log Viewer"
    static let searchPlaceholder = "Search messages, classes…"
    static let exportProgressLabel = "Exporting…"

    static func exportSubtitle(filteredCount: Int) -> String {
        "Export \(filteredCount) filtered entr\(filteredCount == 1 ? "y" : "ies")"
    }

    // MARK: - Input & State

    struct Input {
        let router: ForgeLogFlowRouter
        let buffer: LiveLogBuffer
    }

    struct State {
        var filter: FilterState = FilterState()
        var expandedID: LogEntry.ID?
        var exportingFormat: LogExportFormat?

        static let `default` = State()
    }
}
#endif
