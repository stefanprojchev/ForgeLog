#if os(iOS) || os(visionOS)
import SwiftUI

/// Main log list. Sticky header with stats / sparkline / level cards /
/// search bar / filter chips, scrolling `LazyVStack` of rows below.
struct LogListView: View {
    @ObservedObject var store: LogViewerStore
    @State private var expandedID: LogEntry.ID?
    @State private var presentedSheet: ListSheet?
    @Environment(\.forgeTheme) private var theme

    enum ListSheet: Identifiable {
        case detail(LogEntry)
        case filterPicker(FilterKind)
        case dateRange
        case concepts
        var id: String {
            switch self {
            case .detail(let e):       return "detail-\(e.id)"
            case .filterPicker(let k): return "filter-\(k.rawValue)"
            case .dateRange:           return "date"
            case .concepts:            return "concepts"
            }
        }
    }

    enum FilterKind: String { case module, process, klass }

    var body: some View {
        VStack(spacing: 0) {
            StatsStripView(store: store)
            SparklineView(entries: store.entries)
            LevelCardsView(
                selected: $store.filter.level,
                counts: LevelCounts.compute(from: store.entries)
            )
            SearchAndDateBar(query: $store.filter.query,
                             onOpenDate: { presentedSheet = .dateRange })
            FilterChipsRow(filter: $store.filter,
                           onOpenModule: { presentedSheet = .filterPicker(.module) },
                           onOpenProcess: { presentedSheet = .filterPicker(.process) },
                           onOpenClass: { presentedSheet = .filterPicker(.klass) })
            list
        }
        .background(theme.bg.ignoresSafeArea())
        .toolbar { toolbarContent }
        .toolbarBackground(theme.bgAlt, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(theme.accent)
        .navigationTitle("Log Viewer")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .detail(let entry):
                LogDetailView(entry: entry, siblings: store.filteredEntries)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .filterPicker(let kind):
                FilterPickerView(kind: kind, store: store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .dateRange:
                DateRangePickerView(filter: $store.filter, entries: store.entries)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .concepts:
                LogConceptsView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Log Viewer")
                .font(.headline)
                .foregroundColor(theme.text1)
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                Button(action: { presentedSheet = .concepts }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(theme.accent)
                }
                NavigationLink(destination: SettingsView(store: store)) {
                    Image(systemName: "gearshape")
                        .foregroundColor(theme.accent)
                }
            }
        }
    }

    @ViewBuilder
    private var list: some View {
        if store.filteredEntries.isEmpty {
            EmptyStateView(
                hasFilters: store.filter.hasActiveFilters || store.filter.level != nil,
                onClear: { store.filter.clear() }
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.filteredEntries) { entry in
                        LogRowView(
                            entry: entry,
                            expandedID: $expandedID,
                            onOpenDetail: { presentedSheet = .detail(entry) }
                        )
                        .id(entry.id)
                        .contextMenu {
                            Button { presentedSheet = .detail(entry) } label: {
                                Label("View details", systemImage: "chevron.right")
                            }
                            Button { copyToPasteboard(formatMarkdown(entry)) } label: {
                                Label("Copy entry", systemImage: "doc.on.doc")
                            }
                            Button { copyToPasteboard(entry.message) } label: {
                                Label("Copy message", systemImage: "text.quote")
                            }
                            ShareLink(item: formatMarkdown(entry)) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
            }
        }
    }

    private func formatMarkdown(_ e: LogEntry) -> String {
        var out = "**[\(e.level.displayName.uppercased())]** `\(e.formattedTime)` `\(e.moduleOrFallback)` `\(e.location)`\n\n\(e.message)"
        if let params = e.paramsMetadata, !params.isEmpty {
            out += "\n\n```\n"
            for (k, v) in params.sorted(by: { $0.key < $1.key }) {
                out += "\(k) = \(v.display)\n"
            }
            out += "```"
        }
        if let err = e.loggedError {
            out += "\n\n**Error:** \(err.domain) code \(err.code)\n> \(err.description)"
        }
        return out
    }

    private func copyToPasteboard(_ s: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = s
        #endif
    }
}

// MARK: - Search bar + inline date pill

private struct SearchAndDateBar: View {
    @Binding var query: String
    let onOpenDate: () -> Void
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(theme.text3)
                TextField("", text: $query,
                          prompt: Text("Search messages, classes…")
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
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: onOpenDate) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text("Today").font(theme.sansFont(13, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .frame(height: 36)
                .foregroundColor(theme.accent)
                .background(theme.accentBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.accentBd, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

// MARK: - Module/Process/Class chips

private struct FilterChipsRow: View {
    @Binding var filter: FilterState
    let onOpenModule: () -> Void
    let onOpenProcess: () -> Void
    let onOpenClass: () -> Void
    @Environment(\.forgeTheme) private var theme

    private var activeCount: Int {
        (filter.modules.isEmpty ? 0 : 1) +
        (filter.processes.isEmpty ? 0 : 1) +
        (filter.classes.isEmpty ? 0 : 1)
    }

    var body: some View {
        HStack(spacing: 6) {
            chip(label: "Module",
                 value: display(filter.modules),
                 isActive: !filter.modules.isEmpty,
                 action: onOpenModule)
            chip(label: "Process",
                 value: display(filter.processes),
                 isActive: !filter.processes.isEmpty,
                 action: onOpenProcess)
            chip(label: "Class",
                 value: display(filter.classes),
                 isActive: !filter.classes.isEmpty,
                 action: onOpenClass)
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

    private func display(_ set: Set<String>) -> String {
        guard !set.isEmpty else { return "All" }
        let arr = set.sorted()
        if arr.count == 1 { return arr[0] }
        return "\(arr[0]) +\(arr.count - 1)"
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
