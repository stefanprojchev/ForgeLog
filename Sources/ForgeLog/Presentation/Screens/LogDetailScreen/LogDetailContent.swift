#if os(iOS) || os(visionOS)
import Foundation

enum LogDetailContent {
    // MARK: - Static

    /// Number of entries shown above and below the current entry in the
    /// CONTEXT block.
    static let contextRadius = 4

    static let messageSection = "MESSAGE"
    static let sourceSection = "SOURCE"
    static let processesSectionPrefix = "PROCESSES"
    static let contextSectionPrefix = "CONTEXT"
    static let beforeSection = "BEFORE"
    static let afterSection = "AFTER"

    static let toastMessageCopied = "Message copied"
    static let toastEntryCopied = "Entry copied"
    static func toastMetaCopied(_ key: String) -> String { "\(key) copied" }

    // MARK: - Input & State

    struct Input {
        let router: ForgeLogFlowRouter
        let entry: LogEntry
        let siblings: [LogEntry]
    }

    struct State {
        var currentEntry: LogEntry
        var lastCopied: CopyAction?
        var exportingFormat: LogExportFormat?

        init(entry: LogEntry) {
            self.currentEntry = entry
        }
    }

    // MARK: - Types

    enum CopyAction: Equatable {
        case message
        case fullEntry
        case meta(String)
    }
}
#endif
