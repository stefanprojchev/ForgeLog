#if os(iOS) || os(visionOS)
import SwiftUI

/// Per-level counts. Explicit named fields avoid any `[LogLevel?: Int]`
/// subscript ambiguity where keys can silently mismatch.
struct LevelCounts: Equatable {
    var all: Int
    var debug: Int
    var info: Int
    var warning: Int
    var error: Int

    func count(for level: LogLevel?) -> Int {
        guard let level else { return all }
        switch level {
        case .debug:   return debug
        case .info:    return info
        case .warning: return warning
        case .error:   return error
        }
    }

    static func compute(from entries: [LogEntry]) -> LevelCounts {
        var debug = 0, info = 0, warning = 0, error = 0
        for entry in entries {
            switch entry.level {
            case .debug:   debug += 1
            case .info:    info += 1
            case .warning: warning += 1
            case .error:   error += 1
            }
        }
        return LevelCounts(all: entries.count, debug: debug, info: info, warning: warning, error: error)
    }

    static let zero = LevelCounts(all: 0, debug: 0, info: 0, warning: 0, error: 0)
}

/// Row of 5 cards: All / Debug / Info / Warning / Error with counts.
/// Tapping a card sets `selected`; tapping the active card clears it.
struct LevelCardsView: View {
    @Binding var selected: LogLevel?
    let counts: LevelCounts
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        HStack(spacing: 5) {
            cell(label: "All",     level: nil,      count: counts.all,     severity: theme.allSeverity)
            cell(label: "Debug",   level: .debug,   count: counts.debug,   severity: theme.severity[.debug]!)
            cell(label: "Info",    level: .info,    count: counts.info,    severity: theme.severity[.info]!)
            cell(label: "Warning", level: .warning, count: counts.warning, severity: theme.severity[.warning]!)
            cell(label: "Error",   level: .error,   count: counts.error,   severity: theme.severity[.error]!)
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
