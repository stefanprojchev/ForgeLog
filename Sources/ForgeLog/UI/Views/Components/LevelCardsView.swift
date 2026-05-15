#if os(iOS) || os(visionOS)
import SwiftUI

/// Row of 5 cards: All / Debug / Info / Warning / Error with counts.
/// Tapping a card sets `selected`; tapping the active card clears it.
struct LevelCardsView: View {
    @Binding var selected: LogLevel?
    let counts: [LogLevel?: Int]
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 5) {
            cell(label: "All", level: nil, count: counts[nil] ?? 0, severity: theme.allSeverity)
            ForEach(LogLevel.allCases, id: \.self) { lvl in
                cell(label: lvl.displayName,
                     level: lvl,
                     count: counts[lvl] ?? 0,
                     severity: theme.severity[lvl]!)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(theme.bg)
                .overlay(Rectangle().fill(theme.border).frame(height: 1), alignment: .bottom)
        )
    }

    @ViewBuilder
    private func cell(label: String, level: LogLevel?, count: Int, severity: ForgeLogTheme.Severity) -> some View {
        let isActive = selected == level
        Button(action: { selected = (isActive ? nil : level) }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 8.5, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(severity.fg)
                Text("\(count)")
                    .font(theme.monoFont(15, weight: .semibold))
                    .foregroundColor(theme.text1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 7)
            .background(isActive ? severity.bg : theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isActive ? severity.bd : theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
#endif
