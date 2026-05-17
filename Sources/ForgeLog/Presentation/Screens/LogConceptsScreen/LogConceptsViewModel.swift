#if os(iOS) || os(visionOS)
import Foundation

@Observable @MainActor
final class LogConceptsViewModel {
    // MARK: - Input & State

    let input: LogConceptsContent.Input
    var state = LogConceptsContent.State.default

    // MARK: - Init

    init(input: LogConceptsContent.Input) {
        self.input = input
    }

    // MARK: - Intents

    func dismiss() {
        input.router.dismissSheet()
    }
}
#endif
