#if os(iOS) || os(visionOS)
import SwiftUI

struct LogDetailView: View {
    // MARK: - Properties

    @Bindable var viewModel: LogDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.forgeTheme) private var theme

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroller in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        messageBlock
                        if let params = viewModel.currentEntry.paramsMetadata, !params.isEmpty {
                            ParametersSectionView(params: params)
                        }
                        if let error = viewModel.currentEntry.loggedError {
                            SwiftErrorSectionView(error: error)
                        }
                        sourceSection
                        if !viewModel.currentEntry.processes.isEmpty {
                            processesSection
                        }
                        if !viewModel.contextBefore.isEmpty || !viewModel.contextAfter.isEmpty {
                            contextSection
                        }
                        actions
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
                .background(theme.bg.ignoresSafeArea())
                .overlay(alignment: .bottom) { copyToast }
                .onChange(of: viewModel.currentEntry.id) {
                    withAnimation(.easeOut(duration: 0.18)) {
                        scroller.scrollTo("detail-top", anchor: .top)
                    }
                }
            }
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
            Button("Close") { dismiss() }
                .foregroundColor(theme.accent)
        }
        ToolbarItem(placement: .principal) {
            HStack(spacing: 8) {
                SeverityLetterView(level: viewModel.currentEntry.level, size: 14)
                Text(viewModel.currentEntry.level.displayName)
                    .font(.headline)
                    .foregroundColor(theme.text1)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            ShareLink(item: viewModel.currentEntry.message) {
                Text("Share")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accent)
            }
        }
    }

    private var messageBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(LogDetailContent.messageSection)
                .id("detail-top")
            ZStack(alignment: .topTrailing) {
                Text(viewModel.currentEntry.message)
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
                copyButton
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(LogDetailContent.sourceSection)
            VStack(spacing: 0) {
                metaRowCustom(key: "module", copyValue: viewModel.currentEntry.moduleOrFallback) {
                    ModuleTagView(module: viewModel.currentEntry.moduleOrFallback)
                }
                divider
                metaRow(key: "class", value: viewModel.currentEntry.className, color: theme.text1, mono: true)
                divider
                metaRow(key: "function", value: viewModel.currentEntry.function, color: theme.accent, mono: true)
                divider
                metaRow(key: "line", value: "\(viewModel.currentEntry.line)", color: theme.text1, mono: true)
                divider
                metaRow(key: "id", value: viewModel.currentEntry.id.uuidString, color: theme.text3, mono: true, truncate: true)
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
            sectionLabel("\(LogDetailContent.processesSectionPrefix) · \(viewModel.currentEntry.processes.count)")
            FlowLayout(spacing: 5) {
                ForEach(viewModel.currentEntry.processes, id: \.self) { p in
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

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("\(LogDetailContent.contextSectionPrefix) · \(viewModel.contextBefore.count + viewModel.contextAfter.count) nearby entries")
            VStack(spacing: 0) {
                if !viewModel.contextBefore.isEmpty {
                    contextHeader(title: LogDetailContent.beforeSection, count: viewModel.contextBefore.count, icon: "arrow.up")
                    ForEach(Array(viewModel.contextBefore.enumerated()), id: \.element.id) { idx, entry in
                        contextRow(entry: entry, isLast: idx == viewModel.contextBefore.count - 1 && viewModel.contextAfter.isEmpty)
                    }
                }
                if !viewModel.contextAfter.isEmpty {
                    contextHeader(title: LogDetailContent.afterSection, count: viewModel.contextAfter.count, icon: "arrow.down")
                    ForEach(Array(viewModel.contextAfter.enumerated()), id: \.element.id) { idx, entry in
                        contextRow(entry: entry, isLast: idx == viewModel.contextAfter.count - 1)
                    }
                }
            }
            .background(theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var actions: some View {
        VStack(spacing: 6) {
            actionRow(action: .fullEntry,
                      icon: "doc.on.doc",
                      label: "Copy entry",
                      hint: "Markdown") {
                viewModel.copy(viewModel.markdown, action: .fullEntry)
            }
            actionRow(action: .message,
                      icon: "text.quote",
                      label: "Copy message only",
                      hint: "Plain") {
                viewModel.copy(viewModel.currentEntry.message, action: .message)
            }
            exportMenu
            ShareLink(item: viewModel.markdown) {
                rowChrome(icon: "square.and.arrow.up",
                          label: "Quick share",
                          hint: "Markdown",
                          isCopied: false)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var copyToast: some View {
        if let label = viewModel.toastLabel {
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

    // MARK: - Components

    private var copyButton: some View {
        Button(action: { viewModel.copy(viewModel.currentEntry.message, action: .message) }) {
            HStack(spacing: 4) {
                Image(systemName: viewModel.state.lastCopied == .message ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                Text(viewModel.state.lastCopied == .message ? "copied" : "copy")
                    .font(theme.monoFont(10, weight: .semibold))
            }
            .foregroundColor(viewModel.state.lastCopied == .message ? theme.success : theme.text2)
            .padding(.horizontal, 7)
            .frame(height: 22)
            .background(theme.surfaceHi)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(viewModel.state.lastCopied == .message ? theme.successBd : theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .padding(8)
        .animation(.easeOut(duration: 0.18), value: viewModel.state.lastCopied)
    }

    private var exportMenu: some View {
        Menu {
            Section {
                Text("Export this entry")
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
            }
        } label: {
            rowChrome(icon: viewModel.state.exportingFormat == nil ? "square.and.arrow.up.on.square" : "ellipsis",
                      label: viewModel.state.exportingFormat == nil ? "Export as…" : "Exporting…",
                      hint: viewModel.state.exportingFormat?.displayName,
                      isCopied: false)
        }
        .disabled(viewModel.state.exportingFormat != nil)
    }

    private func metaRow(
        key: String,
        value: String,
        color: Color,
        mono: Bool = false,
        truncate: Bool = false
    ) -> some View {
        let isCopied = viewModel.state.lastCopied == .meta(key)
        return Button(action: { viewModel.copy(value, action: .meta(key)) }) {
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
            .animation(.easeOut(duration: 0.18), value: viewModel.state.lastCopied)
        }
        .buttonStyle(.plain)
    }

    private func metaRowCustom<TrailingDisplay: View>(
        key: String,
        copyValue: String,
        @ViewBuilder display: () -> TrailingDisplay
    ) -> some View {
        let isCopied = viewModel.state.lastCopied == .meta(key)
        return Button(action: { viewModel.copy(copyValue, action: .meta(key)) }) {
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
            .animation(.easeOut(duration: 0.18), value: viewModel.state.lastCopied)
        }
        .buttonStyle(.plain)
    }

    private func contextHeader(title: String, count: Int, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(theme.text3)
            Text("\(title) · \(count)")
                .font(theme.monoFont(9.5, weight: .bold))
                .tracking(0.7)
                .foregroundColor(theme.text3)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(theme.bgAlt)
        .overlay(
            Rectangle().fill(theme.border).frame(height: 0.5),
            alignment: .bottom
        )
    }

    private func contextRow(entry: LogEntry, isLast: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                viewModel.navigateTo(entry)
            }
        } label: {
            HStack(spacing: 10) {
                SeverityLetterView(level: entry.level, size: 16)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.formattedTime)
                            .font(theme.monoFont(10))
                            .foregroundColor(theme.text2)
                        ModuleTagView(module: entry.moduleOrFallback)
                        Text(entry.className)
                            .font(theme.monoFont(10))
                            .foregroundColor(theme.text3)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 0)
                        AttachmentIndicatorView(entry: entry)
                    }
                    Text(entry.message)
                        .font(theme.monoFont(11.5))
                        .foregroundColor(entry.level == .error ? theme.severity[.error]!.fg : theme.text1)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(theme.text3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .overlay(
                Group {
                    if !isLast {
                        Rectangle().fill(theme.border).frame(height: 0.5)
                    }
                },
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }

    private func actionRow(action: LogDetailContent.CopyAction, icon: String, label: String, hint: String?, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            rowChrome(icon: icon,
                      label: label,
                      hint: hint,
                      isCopied: viewModel.state.lastCopied == action)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: viewModel.state.lastCopied)
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

    // MARK: - Private

    private func sectionLabel(_ s: String) -> some View {
        Text(s)
            .font(theme.monoFont(9.5, weight: .bold))
            .tracking(0.7)
            .foregroundColor(theme.text3)
    }

    private var divider: some View {
        Rectangle().fill(theme.border).frame(height: 0.5)
    }
}
#endif
