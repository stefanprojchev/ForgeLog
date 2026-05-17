#if os(iOS) || os(visionOS)
import Foundation

@Observable @MainActor
final class NetworkSettingsViewModel {
    // MARK: - Input & State

    let input: NetworkSettingsContent.Input
    var state = NetworkSettingsContent.State.default

    // MARK: - Init

    init(input: NetworkSettingsContent.Input) {
        self.input = input
    }

    // MARK: - Derived

    var buffer: NetworkLogBuffer { input.buffer }

    var sessionPrefix: String {
        String(buffer.sessionID.uuidString.prefix(8))
    }

    var headerMeta: String {
        let count = buffer.entries.count
        let label = "\(count) request\(count == 1 ? "" : "s")"
        return "\(label) · session \(sessionPrefix)"
    }

    var entryCount: Int { buffer.entries.count }
    var configuration: ForgeNetConfiguration { buffer.configuration }

    // MARK: - Intents

    func requestClearSession() {
        state.isShowingClearConfirmation = true
    }

    func cancelClearSession() {
        state.isShowingClearConfirmation = false
    }

    func confirmClearSession() {
        buffer.clearSession()
        state.isShowingClearConfirmation = false
    }
}
#endif
