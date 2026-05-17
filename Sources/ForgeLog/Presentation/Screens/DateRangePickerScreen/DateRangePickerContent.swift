#if os(iOS) || os(visionOS)
import Foundation

enum DateRangePickerContent {
    // MARK: - Static

    static let histogramDays = 30

    // MARK: - Input & State

    struct Input {
        let router: ForgeLogFlowRouter
        let initialRange: ClosedRange<Date>?
        let entries: [LogEntry]
        let onApply: @MainActor (ClosedRange<Date>?) -> Void
    }

    struct State {
        var startDate: Date = Date()
        var endDate: Date = Date()
        var editing: Endpoint?

        static let `default` = State()
    }

    // MARK: - Types

    enum Endpoint: Identifiable {
        case from, to
        var id: String { self == .from ? "from" : "to" }
    }
}
#endif
