#if os(iOS) || os(visionOS)
import SwiftUI

/// Multi-select picker sheet for Module / Process / Class. Modules are
/// single-select (radios); processes & classes are multi-select (checkboxes).
struct FilterPickerView: View {
    let kind: LogListView.FilterKind
    @ObservedObject var store: LogViewerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    @State private var query: String = ""
    @State private var draft: Set<String> = []

    private var isMulti: Bool { kind != .module }

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
                if isMulti { modeToggle }
                list
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { draft = [] }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Filter · \(title)").font(.headline)
                        Text(draft.isEmpty ? "showing all" : "\(draft.count) selected")
                            .font(theme.monoFont(10.5))
                            .foregroundColor(theme.text3)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") { apply() }.fontWeight(.semibold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { draft = initialDraft }
    }

    private var initialDraft: Set<String> {
        switch kind {
        case .module:  return store.filter.module.map { [$0] } ?? []
        case .process: return store.filter.processes
        case .klass:   return store.filter.classes
        }
    }

    private func apply() {
        switch kind {
        case .module:  store.filter.module = draft.first
        case .process: store.filter.processes = draft
        case .klass:   store.filter.classes = draft
        }
        dismiss()
    }

    private func toggle(_ item: String) {
        if isMulti {
            if draft.contains(item) { draft.remove(item) } else { draft.insert(item) }
        } else {
            draft = draft.contains(item) ? [] : [item]
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(theme.text3)
            TextField("Search \(universe.count) \(title.lowercased())\(universe.count == 1 ? "" : "s")",
                      text: $query)
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

    private var modeToggle: some View {
        Picker("", selection: .constant(0)) {
            Text("Include").tag(0)
            Text("Exclude").tag(1)
            Text("Only").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filtered.isEmpty {
                    Text("No matches for \"\(query)\"")
                        .font(theme.monoFont(12))
                        .foregroundColor(theme.text3)
                        .padding(.top, 40)
                } else {
                    ForEach(filtered, id: \.self) { item in
                        Button(action: { toggle(item) }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: isMulti ? 5 : 10)
                                        .stroke(draft.contains(item) ? theme.accent : theme.borderHi, lineWidth: 1.5)
                                        .background(
                                            RoundedRectangle(cornerRadius: isMulti ? 5 : 10)
                                                .fill(draft.contains(item) ? theme.accent : Color.clear)
                                        )
                                        .frame(width: 20, height: 20)
                                    if draft.contains(item) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(theme.mode == .light ? .white : Color(hex: "#0B0B0E"))
                                    }
                                }
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
}
#endif
