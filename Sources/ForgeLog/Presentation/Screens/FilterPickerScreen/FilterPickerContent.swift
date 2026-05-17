#if os(iOS) || os(visionOS)
import Foundation

enum FilterPickerContent {
    // MARK: - Input & State

    struct Input {
        let router: ForgeLogFlowRouter
        let kind: Kind
        let initialSelection: Set<String>
        let buffer: LiveLogBuffer
        let onApply: @MainActor (Set<String>) -> Void
    }

    struct State {
        var query: String = ""
        var draft: Set<String> = []

        static let `default` = State()
    }

    // MARK: - Types

    enum Kind: String {
        case module, process, klass

        var title: String {
            switch self {
            case .module:  return "Module"
            case .process: return "Process"
            case .klass:   return "Class"
            }
        }
    }
}
#endif
