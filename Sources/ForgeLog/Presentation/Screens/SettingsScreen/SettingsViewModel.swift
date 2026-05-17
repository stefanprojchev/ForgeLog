#if os(iOS) || os(visionOS)
import Foundation

@Observable @MainActor
final class SettingsViewModel {
    // MARK: - Input & State

    let input: SettingsContent.Input
    var state = SettingsContent.State.default

    // MARK: - Init

    init(input: SettingsContent.Input) {
        self.input = input
    }

    // MARK: - Derived

    var buffer: LiveLogBuffer { input.buffer }

    var sessionPrefix: String {
        String(buffer.sessionID.uuidString.prefix(8))
    }

    var headerMeta: String {
        let count = buffer.entries.count
        let entries = "\(count) entr\(count == 1 ? "y" : "ies")"
        return "\(entries) · session \(sessionPrefix)"
    }

    var providers: [ForgeLog.ProviderInfo] { buffer.providers }

    var entryCount: Int { buffer.entries.count }

    var minLevel: LogLevel { buffer.configuration.minLevel }

    var inMemoryLimit: Int { buffer.configuration.inMemoryLimit }

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
