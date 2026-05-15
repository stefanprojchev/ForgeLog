#if os(iOS) || os(visionOS)
import SwiftUI

/// Multi-select picker for Module / Process / Class. All three kinds use the
/// same checkbox UI. The Include/Exclude/Only segmented control is shown for
/// visual completeness but only Include is interactive.
struct FilterPickerView: View {
    let kind: LogListView.FilterKind
    @ObservedObject var store: LogViewerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    @State private var query: String = ""
    @State private var draft: Set<String> = []

    private var universe: [String] {
        switch kind {
        case .module:  return store.allModules
        case .process: return store.allProcesses
        case .klass:   return store.allClasses
        }
    }

    private var counts: [String: Int] {
        var dict: [String: Int] = [:]
        for entry in store.entries {
            switch kind {
            case .module:
                if let m = entry.module { dict[m, default: 0] += 1 }
            case .klass:
                dict[entry.className, default: 0] += 1
            case .process:
                for p in entry.processes { dict[p, default: 0] += 1 }
            }
        }
        return dict
    }

    private var filtered: [String] {
        guard !query.isEmpty else { return universe }
        return universe.filter { $0.lowercased().contains(query.lowercased()) }
    }

    private var title: String {
        switch kind {
        case .module:  return "Module"
        case .process: return "Process"
        case .klass:   return "Class"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                list
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { draft = [] }
                        .foregroundColor(theme.accent)
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Filter · \(title)")
                            .font(.headline)
                            .foregroundColor(theme.text1)
                        Text(draft.isEmpty ? "showing all" : "\(draft.count) selected")
                            .font(theme.monoFont(10.5))
                            .foregroundColor(theme.text3)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") { apply() }
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accent)
                }
            }
            .toolbarBackground(theme.bgAlt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { draft = initialDraft }
    }

    private var initialDraft: Set<String> {
        switch kind {
        case .module:  return store.filter.modules
        case .process: return store.filter.processes
        case .klass:   return store.filter.classes
        }
    }

    private func apply() {
        switch kind {
        case .module:  store.filter.modules = draft
        case .process: store.filter.processes = draft
        case .klass:   store.filter.classes = draft
        }
        dismiss()
    }

    private func toggle(_ item: String) {
        if draft.contains(item) { draft.remove(item) } else { draft.insert(item) }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(theme.text3)
            TextField("", text: $query,
                      prompt: Text("Search \(universe.count) \(title.lowercased())\(universe.count == 1 ? "" : "s")")
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
        .background(theme.surfaceHi)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - List

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filtered.isEmpty {
                    Text(universe.isEmpty
                         ? "No \(title.lowercased())s in the current session"
                         : "No matches for \"\(query)\"")
                        .font(theme.monoFont(12))
                        .foregroundColor(theme.text3)
                        .padding(.top, 40)
                } else {
                    ForEach(filtered, id: \.self) { item in
                        Button(action: { toggle(item) }) {
                            HStack(spacing: 12) {
                                checkbox(checked: draft.contains(item))
                                Text(item)
                                    .font(theme.monoFont(13))
                                    .foregroundColor(draft.contains(item) ? theme.text1 : theme.text2)
                                Spacer()
                                Text("\(counts[item] ?? 0)")
                                    .font(theme.monoFont(10.5))
                                    .foregroundColor(theme.text3)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(draft.contains(item) ? theme.accentBg : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 6)
                    }
                }
            }
            .padding(.bottom, 16)
        }
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
