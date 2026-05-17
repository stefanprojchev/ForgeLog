#if os(iOS) || os(visionOS)
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

/// Drop this anywhere — the only view your app needs to reference for the
/// network viewer. Symmetric with `ForgeLogFlowView`.
///
/// ```swift
/// NavigationStack {
///     ForgeNetFlowView()
/// }
/// ```
public struct ForgeNetFlowView: View {
    // MARK: - Properties

    @AppStorage("forgeTheme") private var themePref: String = "system"
    @Environment(\.colorScheme) private var systemScheme
    @State private var router: ForgeNetFlowRouter

    // MARK: - Init

    @MainActor
    public init() {
        if ForgeNet.shared.buffer == nil {
            ForgeNet.start()
        }
        _router = State(initialValue: ForgeNetFlowRouter(buffer: ForgeNet.shared.buffer!))
    }

    @MainActor
    public init(router: ForgeNetFlowRouter) {
        _router = State(initialValue: router)
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack(path: $router.path) {
            NetworkListView(viewModel: router.makeNetworkListVM())
                .navigationDestination(for: ForgeNetFlowRouter.Route.self) {
                    destination(for: $0)
                }
        }
        .environment(\.forgeTheme, effectiveTheme)
        .preferredColorScheme(preferredColorScheme)
        .sheet(item: $router.presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func destination(for route: ForgeNetFlowRouter.Route) -> some View {
        switch route {
        case .settings:
            NetworkSettingsView(viewModel: router.makeNetworkSettingsVM())
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: ForgeNetFlowRouter.Sheet) -> some View {
        switch sheet {
        case .detail(let entry):
            NetworkDetailView(viewModel: router.makeNetworkDetailVM(entry: entry))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        case .filterPicker(let kind, let current, let onApply):
            NetworkFilterPickerView(viewModel: router.makeNetworkFilterPickerVM(kind: kind, current: current, onApply: onApply))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        case .concepts:
            NetworkConceptsView(viewModel: router.makeNetworkConceptsVM())
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        case .exportResult(let result):
            ExportShareSheet(result: result)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Private

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

/// Backwards-compatibility alias for the pre-refactor entry point. New code
/// should use `ForgeNetFlowView`.
public typealias ForgeNetView = ForgeNetFlowView
#endif
