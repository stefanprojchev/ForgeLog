#if os(iOS) || os(visionOS)
import SwiftUI

/// Drop this anywhere — it's the only view your app needs to reference.
///
/// ```swift
/// NavigationStack {
///     ForgeLogFlowView()
/// }
/// ```
///
/// Reads the active theme preference (`@AppStorage("forgeTheme")`) and the
/// system color scheme, picks the right `ForgeLogTheme`, injects it into the
/// environment, and renders the live log list.
///
/// Owns its own `ForgeLogFlowRouter` (which owns a `LiveLogBuffer` that attaches
/// a `LogViewerProvider` to `ForgeLog.shared`). Use `ForgeLogFlowView(router:)`
/// if you want to share a router across views or pre-seed entries.
public struct ForgeLogFlowView: View {
    // MARK: - Properties

    @AppStorage("forgeTheme") private var themePref: String = "system"
    @Environment(\.colorScheme) private var systemScheme
    @State private var router: ForgeLogFlowRouter

    // MARK: - Init

    public init(configuration: LiveLogBufferConfiguration = .default) {
        _router = State(initialValue: ForgeLogFlowRouter(buffer: LiveLogBuffer(configuration: configuration)))
    }

    public init(router: ForgeLogFlowRouter) {
        _router = State(initialValue: router)
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack(path: $router.path) {
            LogListView(viewModel: router.makeLogListVM())
                .navigationDestination(for: ForgeLogFlowRouter.Route.self) {
                    destination(for: $0)
                }
        }
        .environment(\.forgeTheme, effectiveTheme)
        // Force the SwiftUI color scheme so iOS-native components
        // (DatePicker, Menu, Alert, sheets) render with the same mode
        // as our themed surfaces.
        .preferredColorScheme(preferredColorScheme)
        .sheet(item: $router.presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func destination(for route: ForgeLogFlowRouter.Route) -> some View {
        switch route {
        case .settings:
            SettingsView(viewModel: router.makeSettingsVM())
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: ForgeLogFlowRouter.Sheet) -> some View {
        switch sheet {
        case .detail(let entry, let siblings):
            LogDetailView(viewModel: router.makeLogDetailVM(entry: entry, siblings: siblings))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)

        case .filterPicker(let kind, let current, let onApply):
            FilterPickerView(viewModel: router.makeFilterPickerVM(kind: kind, current: current, onApply: onApply))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)

        case .dateRange(let initialRange, let entries, let onApply):
            DateRangePickerView(viewModel: router.makeDateRangePickerVM(initialRange: initialRange, entries: entries, onApply: onApply))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)

        case .concepts:
            LogConceptsView(viewModel: router.makeLogConceptsVM())
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
/// should use `ForgeLogFlowView`.
public typealias ForgeLogView = ForgeLogFlowView
#endif
