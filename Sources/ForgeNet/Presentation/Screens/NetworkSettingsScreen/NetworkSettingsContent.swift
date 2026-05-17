#if os(iOS) || os(visionOS)
import Foundation

enum NetworkSettingsContent {
    // MARK: - Static

    static let navTitle = "Settings"
    static let appName = "ForgeNet"
    static let appShortCode = "FN"

    static let captureSection = "CAPTURE"
    static let appearanceSection = "APPEARANCE"
    static let redactionSection = "REDACTION"
    static let storageSection = "STORAGE"

    static let clearAlertTitle = "Clear session?"
    static let clearAlertConfirm = "Clear"
    static let clearAlertCancel = "Cancel"
    static func clearAlertMessage(count: Int) -> String {
        "This removes the \(count) in-memory request\(count == 1 ? "" : "s") from the viewer."
    }

    // MARK: - Input & State

    struct Input {
        let buffer: NetworkLogBuffer
    }

    struct State {
        var isShowingClearConfirmation: Bool = false

        static let `default` = State()
    }
}
#endif
