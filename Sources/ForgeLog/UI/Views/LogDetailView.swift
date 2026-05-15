#if os(iOS) || os(visionOS)
import SwiftUI

struct LogDetailView: View {
    let entry: LogEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    messageBlock
                    if let params = entry.paramsMetadata, !params.isEmpty {
                        ParametersSectionView(params: params)
                    }
                    if let error = entry.loggedError {
                        SwiftErrorSectionView(error: error)
                    }
                    sourceSection
                    if !entry.processes.isEmpty {
                        processesSection
                    }
                    actions
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .background(theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        SeverityLetterView(level: entry.level, size: 14)
                        Text(entry.level.displayName).font(.headline)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: entry.message) {
                        Text("Share").fontWeight(.semibold)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var messageBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("MESSAGE")
            ZStack(alignment: .topTrailing) {
                Text(entry.message)
                    .font(theme.monoFont(12.5))
                    .foregroundColor(theme.text1)
                    .lineSpacing(4)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Button(action: { copyToPasteboard(entry.message) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                        Text("copy").font(theme.monoFont(10, weight: .semibold))
                    }
                    .foregroundColor(theme.text2)
                    .padding(.horizontal, 7)
                    .frame(height: 22)
                    .background(theme.surfaceHi)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .padding(8)
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("SOURCE")
            VStack(spacing: 0) {
                MetaRow(key: "module", value: nil, mono: false) {
                    ModuleTagView(module: entry.moduleOrFallback)
                }
                divider
                MetaRow(key: "class", value: entry.className, mono: true, color: theme.text1)
                divider
                MetaRow(key: "function", value: "\(entry.function)", mono: true, color: theme.accent)
                divider
                MetaRow(key: "line", value: "\(entry.line)", mono: true, color: theme.text1)
                divider
                MetaRow(key: "id", value: entry.id.uuidString, mono: true, color: theme.text3, truncate: true)
            }
            .background(theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var processesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("PROCESSES · \(entry.processes.count)")
            FlowLayout(spacing: 5) {
                ForEach(entry.processes, id: \.self) { p in
                    Text("#\(p.replacingOccurrences(of: " ", with: ""))")
                        .font(theme.monoFont(11))
                        .foregroundColor(theme.text1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 6) {
            actionRow(icon: "doc.on.doc", label: "Copy entry", hint: "Markdown") {
                copyToPasteboard(markdown)
            }
            actionRow(icon: "text.quote", label: "Copy message only", hint: "Plain") {
                copyToPasteboard(entry.message)
            }
            ShareLink(item: markdown) {
                rowChrome(icon: "square.and.arrow.up", label: "Share entry", hint: nil, danger: false)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private var markdown: String {
        var out = "**[\(entry.level.displayName.uppercased())]** `\(entry.formattedTime)` `\(entry.moduleOrFallback)` `\(entry.location)`\n\n\(entry.message)"
        if let params = entry.paramsMetadata, !params.isEmpty {
            out += "\n\n```\n"
            for (k, v) in params.sorted(by: { $0.key < $1.key }) {
                out += "\(k) = \(v.display)\n"
            }
            out += "```"
        }
        if let err = entry.loggedError {
            out += "\n\n**Error:** \(err.domain) code \(err.code)\n> \(err.description)"
        }
        return out
    }

    private func actionRow(icon: String, label: String, hint: String?, danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowChrome(icon: icon, label: label, hint: hint, danger: danger)
        }
        .buttonStyle(.plain)
    }

    private func rowChrome(icon: String, label: String, hint: String?, danger: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(danger ? theme.danger : theme.accent)
            Text(label)
                .font(theme.sansFont(13, weight: .medium))
                .foregroundColor(danger ? theme.danger : theme.text1)
            Spacer()
            if let hint {
                Text(hint)
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(theme.text3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func sectionLabel(_ s: String) -> some View {
        Text(s)
            .font(theme.monoFont(9.5, weight: .bold))
            .tracking(0.7)
            .foregroundColor(theme.text3)
    }

    private var divider: some View {
        Rectangle().fill(theme.border).frame(height: 0.5)
    }

    private func copyToPasteboard(_ s: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = s
        #endif
    }
}

// MARK: - MetaRow

struct MetaRow<Trailing: View>: View {
    let key: String
    let value: String?
    let mono: Bool
    var color: Color = .primary
    var truncate: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    @Environment(\.forgeTheme) private var theme

    init(key: String, value: String?, mono: Bool, color: Color = .primary, truncate: Bool = false,
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.key = key
        self.value = value
        self.mono = mono
        self.color = color
        self.truncate = truncate
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(key)
                .font(theme.monoFont(10.5))
                .foregroundColor(theme.text3)
                .frame(width: 70, alignment: .leading)
            if let value {
                Text(value)
                    .font(mono ? theme.monoFont(12) : theme.sansFont(12))
                    .foregroundColor(color)
                    .lineLimit(truncate ? 1 : nil)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                trailing()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Image(systemName: "doc.on.doc")
                .font(.system(size: 12))
                .foregroundColor(theme.text3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
#endif
