#if os(iOS) || os(visionOS)
import SwiftUI
import ForgeLog

/// Status code pill — colored by family. `compact: true` drops the status
/// text suffix so the pill fits in narrow places (redirect chain rows).
struct StatusPillView: View {
    let status: Int?
    let statusText: String?
    var compact: Bool = false
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        let s = theme.statusStyle(status)
        Group {
            if status == nil {
                HStack(spacing: 4) {
                    Text("✕").font(theme.monoFont(compact ? 9 : 10, weight: .bold))
                    Text("FAILED").font(theme.monoFont(compact ? 10 : 11, weight: .bold))
                }
                .foregroundColor(s.fg)
                .padding(.horizontal, compact ? 5 : 7)
                .padding(.vertical, compact ? 1 : 2)
                .background(s.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(s.bd, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3))
            } else if let status {
                HStack(spacing: 5) {
                    Text("\(status)").fontWeight(.bold)
                    if !compact, let statusText {
                        Text(statusText).opacity(0.75)
                    }
                }
                .font(theme.monoFont(compact ? 10 : 11, weight: .medium))
                .tracking(0.3)
                .foregroundColor(s.fg)
                .padding(.horizontal, compact ? 5 : 7)
                .padding(.vertical, compact ? 1 : 2)
                .background(s.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(s.bd, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
    }
}
#endif
