#if os(iOS) || os(visionOS)
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

/// Master list for the network viewer.
struct NetworkListView: View {
    // MARK: - Properties

    @Bindable var viewModel: NetworkListViewModel
    @Environment(\.forgeTheme) private var theme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            NetStatsStripView(buffer: viewModel.buffer)
            NetSparklineView(entries: viewModel.buffer.entries)
            StatusFamilyCardsView(
                selected: Binding(
                    get: { viewModel.state.filter.statusFamily },
                    set: { viewModel.setStatusFamily($0) }
                ),
                counts: viewModel.statusFamilyCounts
            )
            SearchBar(query: $viewModel.state.filter.query)
            FilterChipsRow(
                filter: $viewModel.state.filter,
                onOpenMethod: { viewModel.openMethodFilter() },
                onOpenHost:   { viewModel.openHostFilter() },
                onOpenCaller: { viewModel.openCallerFilter() }
            )
            list
        }
        .background(theme.bg.ignoresSafeArea())
        .toolbar { toolbarContent }
        .toolbarBackground(theme.bgAlt, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(theme.accent)
        .navigationTitle(NetworkListContent.navTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(NetworkListContent.viewerTitle)
                .font(.headline)
                .foregroundColor(theme.text1)
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 14) {
                Button(action: { viewModel.openConcepts() }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(theme.accent)
                }
                exportMenu
                Button(action: { viewModel.openSettings() }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(theme.accent)
                }
            }
        }
    }

    @ViewBuilder
    private var exportMenu: some View {
        Menu {
            Section {
                Text(NetworkListContent.exportSubtitle(filteredCount: viewModel.filteredEntries.count))
            }
            ForEach(LogExportFormat.allCases) { format in
                Button {
                    viewModel.runExport(format: format)
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text(format.displayName)
                            Text(format.subtitle)
                        }
                    } icon: {
                        Image(systemName: format.iconName)
                    }
                }
                .disabled(viewModel.filteredEntries.isEmpty)
            }
        } label: {
            if viewModel.state.exportingFormat != nil {
                ProgressView().scaleEffect(0.75)
            } else {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(viewModel.filteredEntries.isEmpty ? theme.text4 : theme.accent)
            }
        }
        .disabled(viewModel.filteredEntries.isEmpty || viewModel.state.exportingFormat != nil)
    }

    @ViewBuilder
    private var list: some View {
        if viewModel.filteredEntries.isEmpty {
            networkEmpty
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredEntries) { entry in
                        Button(action: { viewModel.openDetail(entry) }) {
                            NetworkRowView(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var networkEmpty: some View {
        VStack(spacing: 14) {
            Image(systemName: "network")
                .font(.system(size: 28))
                .foregroundColor(theme.text3)
                .frame(width: 64, height: 64)
                .background(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(viewModel.hasActiveFilters
                 ? "No requests match your filters"
                 : "No requests yet")
                .font(theme.sansFont(16, weight: .bold))
                .foregroundColor(theme.text1)
            Text(viewModel.hasActiveFilters
                 ? "Try clearing filters or widening the status family."
                 : "Make any URLSession request — ForgeNet captures it automatically.")
                .font(theme.monoFont(12))
                .foregroundColor(theme.text2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear all filters")
                        .font(theme.sansFont(14, weight: .semibold))
                        .foregroundColor(theme.mode == .light ? .white : Color(hex: "#0B0B0E"))
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search bar

private struct SearchBar: View {
    @Binding var query: String
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(theme.text3)
            TextField("", text: $query,
                      prompt: Text(NetworkListContent.searchPlaceholder)
                          .foregroundColor(theme.text3))
                .textFieldStyle(.plain)
                .font(theme.sansFont(13.5))
                .foregroundColor(theme.text1)
                .tint(theme.accent)
            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(theme.text3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

// MARK: - Filter chips

private struct FilterChipsRow: View {
    @Binding var filter: NetworkFilterState
    let onOpenMethod: () -> Void
    let onOpenHost:   () -> Void
    let onOpenCaller: () -> Void
    @Environment(\.forgeTheme) private var theme

    private var activeCount: Int {
        (filter.methods.isEmpty ? 0 : 1) +
        (filter.hosts.isEmpty ? 0 : 1) +
        (filter.callers.isEmpty ? 0 : 1)
    }

    var body: some View {
        HStack(spacing: 6) {
            chip(label: "Method", value: display(filter.methods.map(\.rawValue)),
                 isActive: !filter.methods.isEmpty, action: onOpenMethod)
            chip(label: "Host", value: display(Array(filter.hosts)),
                 isActive: !filter.hosts.isEmpty, action: onOpenHost)
            chip(label: "Caller", value: display(Array(filter.callers)),
                 isActive: !filter.callers.isEmpty, action: onOpenCaller)
            if activeCount > 0 {
                Button(action: { filter.clearChipFilters() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.danger)
                        .frame(width: 36, height: 48)
                        .background(theme.danger.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(theme.danger.opacity(0.28), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private func display(_ arr: [String]) -> String {
        guard !arr.isEmpty else { return "All" }
        let sorted = arr.sorted()
        if sorted.count == 1 { return sorted[0] }
        return "\(sorted[0]) +\(sorted.count - 1)"
    }

    private func chip(label: String, value: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(isActive ? theme.accent.opacity(0.85) : theme.text3)
                HStack(spacing: 4) {
                    Text(value)
                        .font(theme.sansFont(13, weight: .semibold))
                        .foregroundColor(isActive ? theme.accent : theme.text1)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(isActive ? theme.accent : theme.text3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 48)
            .background(isActive ? theme.accentBg : theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isActive ? theme.accentBd : theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
#endif
