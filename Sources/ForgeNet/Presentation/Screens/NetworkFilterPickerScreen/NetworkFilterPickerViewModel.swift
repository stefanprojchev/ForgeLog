#if os(iOS) || os(visionOS)
import Foundation

@Observable @MainActor
final class NetworkFilterPickerViewModel {
    // MARK: - Input & State

    let input: NetworkFilterPickerContent.Input
    var state = NetworkFilterPickerContent.State.default

    // MARK: - Init

    init(input: NetworkFilterPickerContent.Input) {
        self.input = input
        self.state.draft = input.initialSelection
    }

    // MARK: - Derived

    var title: String { input.kind.title }

    var universe: [String] {
        switch input.kind {
        case .method: return HTTPMethod.allCases.map(\.rawValue)
        case .host:   return Array(Set(input.buffer.entries.map(\.host))).sorted()
        case .caller: return Array(Set(input.buffer.entries.compactMap(\.callerModule))).sorted()
        }
    }

    var filtered: [String] {
        guard !state.query.isEmpty else { return universe }
        return universe.filter { $0.lowercased().contains(state.query.lowercased()) }
    }

    var counts: [String: Int] {
        var dict: [String: Int] = [:]
        for entry in input.buffer.entries {
            switch input.kind {
            case .method:
                dict[entry.method.rawValue, default: 0] += 1
            case .host:
                dict[entry.host, default: 0] += 1
            case .caller:
                if let m = entry.callerModule { dict[m, default: 0] += 1 }
            }
        }
        return dict
    }

    // MARK: - Intents

    func toggle(_ item: String) {
        if state.draft.contains(item) { state.draft.remove(item) } else { state.draft.insert(item) }
    }

    func reset() {
        state.draft = []
    }

    func apply() {
        input.onApply(state.draft)
        input.router.dismissSheet()
    }
}
#endif
