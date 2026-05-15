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
            SparklineView(store: store)
            LevelCardsView(
                selected: $store.filter.level,
                counts: levelCounts
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
        .navigationTitle("Log Viewer")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .detail(let entry):
                LogDetailView(entry: entry)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .filterPicker(let kind):
                FilterPickerView(kind: kind, store: store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            case .dateRange:
                DateRangePickerView(filter: $store.filter)
                    .presentationDetents([.medium])
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
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                Button(action: { presentedSheet = .concepts }) {
                    Image(systemName: "info.circle")
                }
                NavigationLink(destination: SettingsView(store: store)) {
                    Image(systemName: "gearshape")
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

    private var levelCounts: [LogLevel?: Int] {
        var dict: [LogLevel?: Int] = [nil: store.entries.count]
        for lvl in LogLevel.allCases {
            dict[lvl] = store.count(for: lvl)
        }
        return dict
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
                TextField("Search messages, classes…", text: $query)
                    .textFieldStyle(.plain)
                    .font(theme.sansFont(13.5))
                    .foregroundColor(theme.text1)
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
        (filter.module == nil ? 0 : 1) +
        (filter.processes.isEmpty ? 0 : 1) +
        (filter.classes.isEmpty ? 0 : 1)
    }

    var body: some View {
        HStack(spacing: 6) {
            chip(label: "Module",
                 value: filter.module ?? "All",
                 isActive: filter.module != nil,
                 action: onOpenModule)
            chip(label: "Process",
                 value: processDisplay,
                 isActive: !filter.processes.isEmpty,
                 action: onOpenProcess)
            chip(label: "Class",
                 value: classDisplay,
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

    private var processDisplay: String {
        guard !filter.processes.isEmpty else { return "All" }
        let arr = Array(filter.processes)
        if arr.count == 1 { return arr[0] }
        return "\(arr[0]) +\(arr.count - 1)"
    }

    private var classDisplay: String {
        guard !filter.classes.isEmpty else { return "All" }
        let arr = Array(filter.classes)
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
