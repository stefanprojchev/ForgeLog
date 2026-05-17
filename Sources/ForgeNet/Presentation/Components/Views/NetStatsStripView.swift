#if os(iOS) || os(visionOS)
import SwiftUI
@_spi(ForgeLogPrimitives) import ForgeLog

/// Strip beneath the nav bar: REC/PAUSED pill + count + size + pause button.
struct NetStatsStripView: View {
    @Bindable var buffer: NetworkLogBuffer
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(buffer.isPaused ? theme.text3 : theme.success)
                    .frame(width: 7, height: 7)
                    .shadow(color: buffer.isPaused ? .clear : theme.success.opacity(0.7),
                            radius: 3)
                Text(buffer.isPaused ? "PAUSED" : "REC")
                    .font(theme.monoFont(11, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(buffer.isPaused ? theme.text3 : theme.success)
            }
            Rectangle().fill(theme.border).frame(width: 1, height: 14)
            (
                Text("\(buffer.entries.count)").foregroundColor(theme.text1).fontWeight(.semibold) +
                Text(" requests · ").foregroundColor(theme.text2) +
                Text(formatTransferred(buffer.totalBytes)).foregroundColor(theme.text1).fontWeight(.semibold)
            )
            .font(theme.monoFont(12.5))
            .tracking(-0.1)
            .lineLimit(1)
            Spacer(minLength: 0)
            Button(action: { buffer.togglePause() }) {
                HStack(spacing: 5) {
                    Image(systemName: buffer.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 10))
                    Text(buffer.isPaused ? "resume" : "pause")
                }
                .font(theme.monoFont(11.5, weight: .semibold))
                .foregroundColor(theme.text1)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(theme.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            Rectangle().fill(theme.bgAlt)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }

    private func formatTransferred(_ n: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(n), countStyle: .file)
    }
}
#endif
