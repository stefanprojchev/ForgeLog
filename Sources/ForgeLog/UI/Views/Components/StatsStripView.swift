#if os(iOS) || os(visionOS)
import SwiftUI

/// Strip beneath the nav bar: LIVE/PAUSED pill + count + rate + pause button.
/// Sits at 44pt so the pause button has a comfortable hit area and the row
/// reads as a proper section, not a thin caption.
struct StatsStripView: View {
    @ObservedObject var store: LogViewerStore
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(store.isPaused ? theme.text3 : theme.success)
                    .frame(width: 7, height: 7)
                    .shadow(color: store.isPaused ? .clear : theme.success.opacity(0.7),
                            radius: 3)
                Text(store.isPaused ? "PAUSED" : "LIVE")
                    .font(theme.monoFont(11, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(store.isPaused ? theme.text3 : theme.success)
            }

            Rectangle()
                .fill(theme.border)
                .frame(width: 1, height: 14)

            (
                Text("\(store.entries.count)").foregroundColor(theme.text1).fontWeight(.semibold) +
                Text(" entries · ").foregroundColor(theme.text2) +
                Text(store.isPaused ? "0" : String(format: "%.1f", store.rate))
                    .foregroundColor(theme.text1).fontWeight(.semibold) +
                Text("/s").foregroundColor(theme.text2)
            )
            .font(theme.monoFont(12.5))
            .tracking(-0.1)
            .lineLimit(1)

            Spacer(minLength: 0)

            Button(action: { store.togglePause() }) {
                HStack(spacing: 5) {
                    Image(systemName: store.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 10))
                    Text(store.isPaused ? "resume" : "pause")
                }
                .font(theme.monoFont(11.5, weight: .semibold))
                .foregroundColor(theme.text1)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            Rectangle()
                .fill(theme.bgAlt)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }
}
#endif
