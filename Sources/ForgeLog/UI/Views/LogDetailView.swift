#if os(iOS) || os(visionOS)
import SwiftUI

struct LogDetailView: View {
    let entry: LogEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    /// Last "copy" action — populated when user taps any copy button. Used by
    /// the overlay toast and by per-row check icons. Auto-clears after 1.5s.
    @State private var lastCopied: CopyAction?

    enum CopyAction: Equatable {
        case message
        case fullEntry
        case meta(String)
    }

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
            .overlay(alignment: .bottom) { copyToast }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(theme.accent)
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        SeverityLetterView(level: entry.level, size: 14)
                        Text(entry.level.displayName)
                            .font(.headline)
                            .foregroundColor(theme.text1)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: entry.message) {
                        Text("Share")
                            .fontWeight(.semibold)
                            .foregroundColor(theme.accent)
                    }
                }
            }
            .toolbarBackground(theme.bgAlt, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Message block

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
                Button(action: { copy(entry.message, action: .message) }) {
                    HStack(spacing: 4) {
                        Image(systemName: lastCopied == .message ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        Text(lastCopied == .message ? "copied" : "copy")
                            .font(theme.monoFont(10, weight: .semibold))
                    }
                    .foregroundColor(lastCopied == .message ? theme.success : theme.text2)
                    .padding(.horizontal, 7)
                    .frame(height: 22)
                    .background(theme.surfaceHi)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(lastCopied == .message ? theme.successBd : theme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .padding(8)
                .animation(.easeOut(duration: 0.18), value: lastCopied)
            }
        }
    }

    // MARK: - Source

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("SOURCE")
            VStack(spacing: 0) {
                metaRowCustom(key: "module", copyValue: entry.moduleOrFallback) {
                    ModuleTagView(module: entry.moduleOrFallback)
                }
                divider
                metaRow(key: "class", value: entry.className, color: theme.text1, mono: true)
                divider
                metaRow(key: "function", value: entry.function, color: theme.accent, mono: true)
                divider
                metaRow(key: "line", value: "\(entry.line)", color: theme.text1, mono: true)
                divider
                metaRow(key: "id", value: entry.id.uuidString, color: theme.text3, mono: true, truncate: true)
            }
            .background(theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func metaRow(
        key: String,
        value: String,
        color: Color,
        mono: Bool = false,
        truncate: Bool = false
    ) -> some View {
        let isCopied = lastCopied == .meta(key)
        return Button(action: { copy(value, action: .meta(key)) }) {
            HStack(spacing: 10) {
                Text(key)
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
                    .frame(width: 70, alignment: .leading)
                Text(value)
                    .font(mono ? theme.monoFont(12) : theme.sansFont(12))
                    .foregroundColor(color)
                    .lineLimit(truncate ? 1 : nil)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundColor(isCopied ? theme.success : theme.text3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.18), value: lastCopied)
        }
        .buttonStyle(.plain)
    }

    private func metaRowCustom<TrailingDisplay: View>(
        key: String,
        copyValue: String,
        @ViewBuilder display: () -> TrailingDisplay
    ) -> some View {
        let isCopied = lastCopied == .meta(key)
        return Button(action: { copy(copyValue, action: .meta(key)) }) {
            HStack(spacing: 10) {
                Text(key)
                    .font(theme.monoFont(10.5))
                    .foregroundColor(theme.text3)
                    .frame(width: 70, alignment: .leading)
                display()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundColor(isCopied ? theme.success : theme.text3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.18), value: lastCopied)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Processes

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

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 6) {
            actionRow(action: .fullEntry,
                      icon: "doc.on.doc",
                      label: "Copy entry",
                      hint: "Markdown") {
                copy(markdown, action: .fullEntry)
            }
            actionRow(action: .message,
                      icon: "text.quote",
                      label: "Copy message only",
                      hint: "Plain") {
                copy(entry.message, action: .message)
            }
            ShareLink(item: markdown) {
                rowChrome(icon: "square.and.arrow.up",
                          label: "Share entry",
                          hint: nil,
                          isCopied: false)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private func actionRow(action: CopyAction, icon: String, label: String, hint: String?, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            rowChrome(icon: icon,
                      label: label,
                      hint: hint,
                      isCopied: lastCopied == action)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: lastCopied)
    }

    private func rowChrome(icon: String, label: String, hint: String?, isCopied: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isCopied ? "checkmark" : icon)
                .font(.system(size: 14))
                .foregroundColor(isCopied ? theme.success : theme.accent)
            Text(isCopied ? "Copied!" : label)
                .font(theme.sansFont(13, weight: .medium))
                .foregroundColor(theme.text1)
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
        .background(isCopied ? theme.success.opacity(0.06) : theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCopied ? theme.successBd : theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Toast

    @ViewBuilder
    private var copyToast: some View {
        if let label = toastLabel {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.success)
                Text(label)
                    .font(theme.sansFont(13, weight: .semibold))
                    .foregroundColor(theme.text1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.successBd, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var toastLabel: String? {
        guard let lastCopied else { return nil }
        switch lastCopied {
        case .message:        return "Message copied"
        case .fullEntry:      return "Entry copied"
        case .meta(let key):  return "\(key) copied"
        }
    }

    // MARK: - Markdown

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

    // MARK: - Helpers

    private func sectionLabel(_ s: String) -> some View {
        Text(s)
            .font(theme.monoFont(9.5, weight: .bold))
            .tracking(0.7)
            .foregroundColor(theme.text3)
    }

    private var divider: some View {
        Rectangle().fill(theme.border).frame(height: 0.5)
    }

    private func copy(_ text: String, action: CopyAction) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
        withAnimation(.easeOut(duration: 0.18)) {
            lastCopied = action
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            withAnimation(.easeIn(duration: 0.18)) {
                if lastCopied == action { lastCopied = nil }
            }
        }
    }
}
#endif
