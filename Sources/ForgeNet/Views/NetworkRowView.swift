#if os(iOS) || os(visionOS)
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

struct NetworkRowView: View {
    let entry: NetworkLogEntry
    @Environment(\.forgeTheme) private var theme

    private var statusSev: ForgeLogTheme.Severity { theme.statusStyle(entry.status) }
    private var isError: Bool {
        if entry.failed { return true }
        return (entry.status ?? 0) >= 400
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(statusSev.fg)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                metaLine
                pathLine
                bottomLine
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 56)
        .background(isError ? statusSev.bg : Color.clear)
        .overlay(Rectangle().fill(theme.border).frame(height: 0.5), alignment: .bottom)
    }

    private var metaLine: some View {
        HStack(spacing: 6) {
            MethodBadgeView(method: entry.method)
            Text(entry.formattedTime)
                .font(theme.monoFont(10.5))
                .foregroundColor(theme.text2)
                .tracking(-0.1)
            Text(entry.host)
                .font(theme.monoFont(11, weight: .semibold))
                .foregroundColor(theme.text1)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            edgeChips
        }
    }

    private var edgeChips: some View {
        HStack(spacing: 3) {
            if let chain = entry.redirectChain, chain.count > 1 {
                EdgeChipView(label: "↪\(chain.count)", kind: .neutral)
            }
            if entry.isGzip   { EdgeChipView(label: "GZIP", kind: .info) }
            if entry.streaming { EdgeChipView(label: "SSE",  kind: .success) }
            if entry.isImage   { EdgeChipView(label: "IMG",  kind: .warn) }
        }
    }

    private var pathLine: some View {
        let queryStr = entry.query.isEmpty
            ? ""
            : "?" + entry.query.map { "\($0.key)=\($0.value ?? "null")" }.joined(separator: "&")
        return (
            Text(entry.path).foregroundColor(theme.text1) +
            Text(queryStr).foregroundColor(theme.text3)
        )
        .font(theme.monoFont(12.5))
        .tracking(-0.1)
        .lineLimit(1)
        .truncationMode(.middle)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomLine: some View {
        HStack(spacing: 8) {
            StatusPillView(status: entry.status, statusText: entry.statusText)
            stats
            Spacer(minLength: 0)
            if let mod = entry.callerModule {
                ModuleTagView(module: mod)
            }
        }
    }

    private var stats: some View {
        let isSlow = entry.durationMs > 1000
        let durColor: Color = isSlow ? theme.severity[.warning]!.fg : theme.text2
        return (
            Text(entry.formattedDuration)
                .foregroundColor(durColor)
                .fontWeight(isSlow ? .semibold : .regular) +
            Text(" · ").foregroundColor(theme.text4) +
            Text("↑ \(formatBytes(entry.requestBytes))").foregroundColor(theme.text2) +
            Text(" · ").foregroundColor(theme.text4) +
            Text("↓ \(formatBytes(entry.responseBytes))").foregroundColor(theme.text2)
        )
        .font(theme.monoFont(10.5))
        .tracking(-0.1)
    }

    private func formatBytes(_ n: Int) -> String {
        if n == 0 { return "—" }
        if n < 1024 { return "\(n) B" }
        if n < 1024 * 1024 { return String(format: "%.1f KB", Double(n) / 1024.0) }
        return String(format: "%.1f MB", Double(n) / 1_048_576.0)
    }
}
#endif
