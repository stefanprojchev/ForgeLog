#if os(iOS) || os(visionOS)
import Foundation

@Observable @MainActor
final class NetworkConceptsViewModel {
    // MARK: - Input & State

    let input: NetworkConceptsContent.Input
    var state = NetworkConceptsContent.State.default

    // MARK: - Init

    init(input: NetworkConceptsContent.Input) {
        self.input = input
    }

    // MARK: - Intents

    func dismiss() {
        input.router.dismissSheet()
    }
}
#endif
