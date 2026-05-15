#if os(iOS) || os(visionOS)
import SwiftUI

/// Drop this anywhere — it's the only view your app needs to reference.
///
/// ```swift
/// NavigationStack {
///     ForgeLogView()
/// }
/// ```
///
/// Reads the active theme preference (`@AppStorage("forgeTheme")`) and the
/// system color scheme, picks the right `ForgeLogTheme`, injects it into the
/// environment, and renders the live log list.
///
/// Owns its own `LogViewerStore` (which attaches a `LogViewerProvider` to
/// `ForgeLog.shared`). Use `ForgeLogView(store:)` if you want to share a
/// store across views or pre-seed entries.
public struct ForgeLogView: View {
    @AppStorage("forgeTheme") private var themePref: String = "system"
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var store: LogViewerStore

    public init(configuration: LogViewerConfiguration = .default) {
        _store = StateObject(wrappedValue: LogViewerStore(configuration: configuration))
    }

    public init(store: LogViewerStore) {
        _store = StateObject(wrappedValue: store)
    }

    public var body: some View {
        LogListView(store: store)
            .environment(\.forgeTheme, effectiveTheme)
            // Force the SwiftUI color scheme so iOS-native components
            // (DatePicker, Menu, Alert, sheets) render with the same mode
            // as our themed surfaces. Without this, picking "Dark" in our
            // settings while the phone is in Light keeps the DatePicker
            // bright white over our dark canvas.
            .preferredColorScheme(preferredColorScheme)
    }

    private var effectiveTheme: ForgeLogTheme {
        switch themePref {
        case "dark":  return .dark
        case "light": return .light
        default:      return systemScheme == .dark ? .dark : .light
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch themePref {
        case "dark":  return .dark
        case "light": return .light
        default:      return nil   // follow system
        }
    }
}
#endif
