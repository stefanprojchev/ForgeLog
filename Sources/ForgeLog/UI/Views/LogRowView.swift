#if os(iOS) || os(visionOS)
import SwiftUI

/// Single log entry row. Two visual states:
/// - **Collapsed** (default): severity gutter + meta line + truncated message
/// - **Expanded**: full message + process tags + params preview + error preview
///   + "View full details" link
///
/// Long-press triggers the system context menu (handled by `LogListView`).
struct LogRowView: View {
    let entry: LogEntry
    @Binding var expandedID: LogEntry.ID?
    let onOpenDetail: () -> Void
    @Environment(\.forgeTheme) private var theme

    private var isExpanded: Bool { expandedID == entry.id }
    private var severity: ForgeLogTheme.Severity { theme.severity[entry.level]! }

    var body: some View {
        HStack(spacing: 0) {
            severityGutter
            VStack(alignment: .leading, spacing: 3) {
                metaLine
                messageLine
                if isExpanded {
                    expandedContent
                        .padding(.top, 5)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 44)
        .background(rowBackground)
        .overlay(Rectangle().fill(theme.border).frame(height: 0.5), alignment: .bottom)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.18)) {
                expandedID = isExpanded ? nil : entry.id
            }
        }
    }

    private var severityGutter: some View {
        Text(entry.level.letter)
            .font(theme.monoFont(11.5, weight: .bold))
            .foregroundColor(severity.fg)
            .frame(width: 24, alignment: .center)
            .padding(.top, 9)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(severity.bg)
            .overlay(Rectangle().fill(severity.bd).frame(width: 1), alignment: .trailing)
    }

    private var metaLine: some View {
        HStack(spacing: 6) {
            Text(entry.formattedTime)
                .font(theme.monoFont(10.5))
                .foregroundColor(theme.text2)
                .tracking(-0.1)

            ModuleTagView(module: entry.moduleOrFallback)

            (
                Text(entry.className).foregroundColor(theme.text1) +
                Text(".\(entry.function)").foregroundColor(theme.text3) +
                Text(":\(entry.line)").foregroundColor(theme.text4)
            )
            .font(theme.monoFont(10.5))
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)

            AttachmentIndicatorView(entry: entry)
        }
    }

    private var messageLine: some View {
        Text(entry.message)
            .font(theme.monoFont(12))
            .tracking(-0.1)
            .foregroundColor(entry.level == .error ? severity.fg : theme.text1)
            .lineLimit(isExpanded ? nil : 1)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().background(theme.border)

            if !entry.processes.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(entry.processes, id: \.self) { p in
                        Text("#\(p.replacingOccurrences(of: " ", with: ""))")
                            .font(theme.monoFont(9.5))
                            .foregroundColor(theme.text2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.surfaceHi)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(theme.border, lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
            }

            if let params = entry.paramsMetadata, !params.isEmpty {
                paramsPreview(params: params)
            }

            if let error = entry.loggedError {
                errorPreview(error: error)
            }

            Button(action: onOpenDetail) {
                HStack(spacing: 4) {
                    Text("View full details")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                }
                .font(theme.sansFont(13, weight: .semibold))
                .foregroundColor(theme.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private func paramsPreview(params: [String: AnyCodableValue]) -> some View {
        let entries = Array(params.prefix(3))
        let more = params.count - entries.count
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(entries, id: \.key) { kv in
                HStack(spacing: 8) {
                    Text(kv.key)
                        .foregroundColor(theme.text3)
                    Text(kv.value.display)
                        .foregroundColor(theme.text1)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .font(theme.monoFont(11))
            }
            if more > 0 {
                Text("+\(more) more")
                    .font(theme.monoFont(10))
                    .foregroundColor(theme.text3)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func errorPreview(error: LoggedError) -> some View {
        let err = theme.severity[.error]!
        return VStack(alignment: .leading, spacing: 3) {
            Text("\(error.domain) · code \(error.code)")
                .font(theme.monoFont(10, weight: .bold))
                .tracking(0.4)
                .foregroundColor(err.fg)
            Text(error.description)
                .font(theme.monoFont(11))
                .foregroundColor(theme.text1)
                .lineLimit(2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(err.bg)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(err.bd, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var rowBackground: some View {
        let base: Color = {
            if isExpanded {
                return theme.mode == .light
                    ? Color.black.opacity(0.025)
                    : Color.white.opacity(0.03)
            }
            if entry.level == .error {
                return theme.mode == .light
                    ? Color(hex: "#C7302C").opacity(0.04)
                    : Color(hex: "#FF6B6B").opacity(0.04)
            }
            return .clear
        }()
        return base
    }
}

// MARK: - Flow layout helper

/// Minimal flow layout for the process tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let result = arrange(subviews: subviews, in: width)
        return CGSize(width: width, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(subviews: subviews, in: bounds.width)
        for (i, frame) in result.frames.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                              proposal: ProposedViewSize(width: frame.width, height: frame.height))
        }
    }

    private func arrange(subviews: Subviews, in width: CGFloat) -> (frames: [CGRect], height: CGFloat) {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return (frames, y + lineHeight)
    }
}
#endif
