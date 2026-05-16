#if os(iOS) || os(visionOS)
import SwiftUI
import ForgeLog

/// Colored HTTP-method pill. Min-width keeps the column visually stable when
/// methods change length (GET vs DELETE).
struct MethodBadgeView: View {
    let method: HTTPMethod
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        let s = theme.methodStyle(method)
        Text(method.rawValue)
            .font(theme.monoFont(9.5, weight: .bold))
            .tracking(0.5)
            .foregroundColor(s.fg)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .frame(minWidth: 42)
            .background(s.bg)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(s.bd, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
#endif
