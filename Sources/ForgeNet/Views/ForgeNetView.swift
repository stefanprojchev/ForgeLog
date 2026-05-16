#if os(iOS) || os(visionOS)
import SwiftUI
import ForgeLog

/// Drop this anywhere — the only view your app needs to reference for the
/// network viewer. Symmetric with `ForgeLogView`.
///
/// ```swift
/// NavigationStack {
///     ForgeNetView()
/// }
/// ```
///
/// Shares the `forgeTheme` AppStorage key with `ForgeLogView` so picking a
/// theme in either viewer applies to both.
public struct ForgeNetView: View {
    @AppStorage("forgeTheme") private var themePref: String = "system"
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var store: NetworkLogStore

    @MainActor
    public init() {
        if ForgeNet.shared.store == nil {
            ForgeNet.start()
        }
        _store = StateObject(wrappedValue: ForgeNet.shared.store!)
    }

    @MainActor
    public init(store: NetworkLogStore) {
        _store = StateObject(wrappedValue: store)
    }

    public var body: some View {
        NetworkListView(store: store)
            .environment(\.forgeTheme, effectiveTheme)
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
        default:      return nil
        }
    }
}
#endif
