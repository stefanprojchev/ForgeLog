#if os(iOS) || os(visionOS)
import Foundation

enum SettingsContent {
    // MARK: - Static

    static let navTitle = "Settings"
    static let captureSection = "CAPTURE"
    static let appearanceSection = "APPEARANCE"
    static let providersSectionPrefix = "PROVIDERS"
    static let storageSection = "STORAGE"

    static let appName = "ForgeLog"
    static let appShortCode = "FL"

    static let clearAlertTitle = "Clear session?"
    static let clearAlertConfirm = "Clear"
    static let clearAlertCancel = "Cancel"
    static func clearAlertMessage(count: Int) -> String {
        "This removes the \(count) in-memory entries from the viewer. Persisted logs on disk are unaffected."
    }

    // MARK: - Input & State

    struct Input {
        let buffer: LiveLogBuffer
    }

    struct State {
        var isShowingClearConfirmation: Bool = false

        static let `default` = State()
    }
}
#endif
