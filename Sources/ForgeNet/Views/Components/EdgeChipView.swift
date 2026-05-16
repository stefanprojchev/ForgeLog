#if os(iOS) || os(visionOS)
import SwiftUI
import ForgeLog

/// Inline edge-case chip — `↪3` for redirect chains, `GZIP`, `SSE`, `IMG`,
/// `RETRY`. Pulls colors from the existing severity palette so dark/light
/// stays consistent.
struct EdgeChipView: View {
    let label: String
    let kind: Kind
    @Environment(\.forgeTheme) private var theme

    enum Kind { case info, success, warn, error, neutral }

    var body: some View {
        let s: ForgeLogTheme.Severity = {
            switch kind {
            case .info:    return theme.severity[.info]!
            case .success: return ForgeLogTheme.Severity(
                fg: theme.success,
                dim: theme.success,
                bg: theme.success.opacity(0.10),
                bd: theme.successBd
            )
            case .warn:    return theme.severity[.warning]!
            case .error:   return theme.severity[.error]!
            case .neutral: return theme.severity[.debug]!
            }
        }()
        Text(label)
            .font(theme.monoFont(9, weight: .bold))
            .tracking(0.3)
            .foregroundColor(s.fg)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(s.bg)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(s.bd, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
#endif
