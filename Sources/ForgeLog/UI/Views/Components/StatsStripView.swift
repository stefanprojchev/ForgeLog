#if os(iOS) || os(visionOS)
import SwiftUI

/// 30pt-tall strip beneath the nav bar: LIVE/PAUSED pill + count + rate +
/// pause button.
struct StatsStripView: View {
    @ObservedObject var store: LogViewerStore
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Circle()
                    .fill(store.isPaused ? theme.text3 : theme.success)
                    .frame(width: 6, height: 6)
                    .shadow(color: store.isPaused ? .clear : theme.success.opacity(0.7),
                            radius: 3)
                Text(store.isPaused ? "PAUSED" : "LIVE")
                    .font(theme.monoFont(9.5, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(store.isPaused ? theme.text3 : theme.success)
            }

            Rectangle()
                .fill(theme.border)
                .frame(width: 1, height: 10)

            (
                Text("\(store.entries.count)").foregroundColor(theme.text1).fontWeight(.semibold) +
                Text(" entries · ").foregroundColor(theme.text2) +
                Text(store.isPaused ? "0" : String(format: "%.1f", store.rate))
                    .foregroundColor(theme.text1).fontWeight(.semibold) +
                Text("/s").foregroundColor(theme.text2)
            )
            .font(theme.monoFont(11))
            .tracking(-0.1)
            .lineLimit(1)

            Spacer(minLength: 0)

            Button(action: { store.togglePause() }) {
                HStack(spacing: 4) {
                    Image(systemName: store.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 8))
                    Text(store.isPaused ? "resume" : "pause")
                }
                .font(theme.monoFont(10, weight: .semibold))
                .foregroundColor(theme.text2)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 30)
        .background(
            Rectangle()
                .fill(theme.bgAlt)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }
}
#endif
