#if os(iOS) || os(visionOS)
import SwiftUI

struct LogEmptyStateView: View {
    let hasFilters: Bool
    let onClear: () -> Void
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(theme.text3)
                .frame(width: 64, height: 64)
                .background(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(hasFilters ? "No logs match your filters" : "No logs yet")
                .font(theme.sansFont(16, weight: .bold))
                .foregroundColor(theme.text1)

            Text(hasFilters
                 ? "Try a wider date range, lower the severity, or clear filters to see all entries from this session."
                 : "Call ForgeLog.shared.info(\"Hello, world\") from anywhere in your app to start logging.")
                .font(theme.monoFont(12))
                .foregroundColor(theme.text2)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 280)

            if hasFilters {
                Button(action: onClear) {
                    Text("Clear all filters")
                        .font(theme.sansFont(14, weight: .semibold))
                        .foregroundColor(theme.mode == .light ? .white : Color(hex: "#0B0B0E"))
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
