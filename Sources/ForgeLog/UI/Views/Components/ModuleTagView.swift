#if os(iOS) || os(visionOS)
import SwiftUI

/// Colored module pill — uppercase mono with a tinted background.
struct ModuleTagView: View {
    let module: String
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        let c = theme.moduleColor(for: module)
        Text(module.uppercased())
            .font(theme.monoFont(9.5, weight: .bold))
            .tracking(0.6)
            .foregroundColor(c)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(c.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(c.opacity(0.20), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
#endif
