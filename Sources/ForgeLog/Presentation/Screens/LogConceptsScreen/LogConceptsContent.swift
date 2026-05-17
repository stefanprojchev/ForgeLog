#if os(iOS) || os(visionOS)
import Foundation

enum LogConceptsContent {
    // MARK: - Static

    static let navTitle = "Log Concepts"
    static let intro = "ForgeLog organizes every entry by four dimensions. Tap any of these to filter the live log stream."

    static let concepts: [Concept] = [
        .init(
            title: "Module",
            blurb: "The Swift module (or SPM package) that produced the log entry. Extracted automatically from the source file path at the call site.",
            example: "A log in NetworkKit will show NetworkKit as the module. Filter by module to isolate logs from one package."
        ),
        .init(
            title: "Class",
            blurb: "The Swift file name where the log call was made, without the .swift extension. Despite the name, this is the file rather than a specific class.",
            example: "A log in FeedViewModel.swift shows FeedViewModel as the class. Filter by class to see all logs originating from one file."
        ),
        .init(
            title: "Process",
            blurb: "One or more labels you can attach to a log call to group related operations. A single log can belong to multiple processes. Processes are user-defined.",
            example: "A log about importing Instagram media might be tagged with both #Import and #Instagram. Filter by either and the entry will appear."
        ),
        .init(
            title: "Level",
            blurb: "Severity of the log entry. From lowest to highest: Debug, Info, Warning, Error. Each provider sets a minimum level to control which entries it receives.",
            example: "Use Debug for diagnostics, Info for general events, Warning for recoverable issues, Error for failures."
        ),
    ]

    // MARK: - Input & State

    struct Input {
        let router: ForgeLogFlowRouter
    }

    struct State {
        static let `default` = State()
    }

    // MARK: - Types

    struct Concept {
        let title: String
        let blurb: String
        let example: String
    }
}
#endif
