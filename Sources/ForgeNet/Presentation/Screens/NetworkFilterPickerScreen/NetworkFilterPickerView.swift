#if os(iOS) || os(visionOS)
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

/// Multi-select picker for Method / Host / Caller.
struct NetworkFilterPickerView: View {
    // MARK: - Properties

    @Bindable var viewModel: NetworkFilterPickerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                list
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar { toolbarContent }
            .toolbarBackground(theme.bgAlt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Reset") { viewModel.reset() }
                .foregroundColor(theme.accent)
        }
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text("Filter · \(viewModel.title)")
                    .font(.headline)
                    .foregroundColor(theme.text1)
                Text(viewModel.state.draft.isEmpty ? "showing all" : "\(viewModel.state.draft.count) selected")
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Apply") { viewModel.apply() }
                .fontWeight(.semibold)
                .foregroundColor(theme.accent)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(theme.text3)
            TextField("", text: $viewModel.state.query,
                      prompt: Text("Search \(viewModel.universe.count) \(viewModel.title.lowercased())\(viewModel.universe.count == 1 ? "" : "s")")
                          .foregroundColor(theme.text3))
                .textFieldStyle(.plain)
                .font(theme.sansFont(13.5))
                .foregroundColor(theme.text1)
                .tint(theme.accent)
            if !viewModel.state.query.isEmpty {
                Button(action: { viewModel.state.query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(theme.text3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(theme.surfaceHi)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.filtered.isEmpty {
                    Text(viewModel.universe.isEmpty
                         ? "No \(viewModel.title.lowercased())s in the current session"
                         : "No matches for \"\(viewModel.state.query)\"")
                        .font(theme.monoFont(12))
                        .foregroundColor(theme.text3)
                        .padding(.top, 40)
                } else {
                    ForEach(viewModel.filtered, id: \.self) { item in
                        row(for: item)
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Components

    private func row(for item: String) -> some View {
        Button(action: { viewModel.toggle(item) }) {
            HStack(spacing: 12) {
                checkbox(checked: viewModel.state.draft.contains(item))
                if viewModel.input.kind == .method, let m = HTTPMethod(rawValue: item) {
                    MethodBadgeView(method: m)
                } else if viewModel.input.kind == .caller {
                    ModuleTagView(module: item)
                }
                Text(item)
                    .font(theme.monoFont(13))
                    .foregroundColor(viewModel.state.draft.contains(item) ? theme.text1 : theme.text2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text("\(viewModel.counts[item] ?? 0)")
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.state.draft.contains(item) ? theme.accentBg : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }

    private func checkbox(checked: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(checked ? theme.accent : theme.borderHi, lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(checked ? theme.accent : Color.clear)
                )
                .frame(width: 20, height: 20)
            if checked {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.mode == .light ? .white : Color(hex: "#0B0B0E"))
            }
        }
    }
}
#endif
