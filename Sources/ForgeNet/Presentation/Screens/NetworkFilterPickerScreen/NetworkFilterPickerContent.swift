#if os(iOS) || os(visionOS)
import Foundation

enum NetworkFilterPickerContent {
    // MARK: - Input & State

    struct Input {
        let router: ForgeNetFlowRouter
        let kind: Kind
        let initialSelection: Set<String>
        let buffer: NetworkLogBuffer
        let onApply: @MainActor (Set<String>) -> Void
    }

    struct State {
        var query: String = ""
        var draft: Set<String> = []

        static let `default` = State()
    }

    // MARK: - Types

    enum Kind: String {
        case method, host, caller

        var title: String {
            switch self {
            case .method: return "Method"
            case .host:   return "Host"
            case .caller: return "Caller"
            }
        }
    }
}
#endif
