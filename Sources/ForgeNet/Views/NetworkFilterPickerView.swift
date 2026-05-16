#if os(iOS) || os(visionOS)
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

/// Multi-select picker for Method / Host / Caller. Matches the styling of
/// the log-side `FilterPickerView` — search field, checkbox list, no
/// Include/Exclude/Only tabs.
struct NetworkFilterPickerView: View {
    let kind: NetworkListView.FilterKind
    @ObservedObject var store: NetworkLogStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    @State private var query: String = ""
    @State private var draft: Set<String> = []

    private var universe: [String] {
        switch kind {
        case .method: return HTTPMethod.allCases.map(\.rawValue)
        case .host:   return store.allHosts
        case .caller: return store.allCallers
        }
    }

    private var counts: [String: Int] {
        var dict: [String: Int] = [:]
        for entry in store.entries {
            switch kind {
            case .method:
                dict[entry.method.rawValue, default: 0] += 1
            case .host:
                dict[entry.host, default: 0] += 1
            case .caller:
                if let m = entry.callerModule { dict[m, default: 0] += 1 }
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
        case .method: return "Method"
        case .host:   return "Host"
        case .caller: return "Caller"
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
        case .method: return Set(store.filter.methods.map(\.rawValue))
        case .host:   return store.filter.hosts
        case .caller: return store.filter.callers
        }
    }

    private func apply() {
        switch kind {
        case .method:
            store.filter.methods = Set(draft.compactMap(HTTPMethod.init(rawValue:)))
        case .host:
            store.filter.hosts = draft
        case .caller:
            store.filter.callers = draft
        }
        dismiss()
    }

    private func toggle(_ item: String) {
        if draft.contains(item) { draft.remove(item) } else { draft.insert(item) }
    }

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
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

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
                                if kind == .method, let m = HTTPMethod(rawValue: item) {
                                    MethodBadgeView(method: m)
                                } else if kind == .caller {
                                    ModuleTagView(module: item)
                                }
                                Text(item)
                                    .font(theme.monoFont(13))
                                    .foregroundColor(draft.contains(item) ? theme.text1 : theme.text2)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
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
