#if os(iOS) || os(visionOS)
import Foundation

@Observable @MainActor
final class FilterPickerViewModel {
    // MARK: - Input & State

    let input: FilterPickerContent.Input
    var state = FilterPickerContent.State.default

    // MARK: - Init

    init(input: FilterPickerContent.Input) {
        self.input = input
        self.state.draft = input.initialSelection
    }

    // MARK: - Derived

    var title: String { input.kind.title }

    var universe: [String] {
        switch input.kind {
        case .module:  return Array(Set(input.buffer.entries.compactMap(\.module))).sorted()
        case .process: return Array(Set(input.buffer.entries.flatMap(\.processes))).sorted()
        case .klass:   return Array(Set(input.buffer.entries.map(\.className))).sorted()
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
            case .module:
                if let m = entry.module { dict[m, default: 0] += 1 }
            case .klass:
                dict[entry.className, default: 0] += 1
            case .process:
                for p in entry.processes { dict[p, default: 0] += 1 }
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
