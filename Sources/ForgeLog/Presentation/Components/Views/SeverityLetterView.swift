#if os(iOS) || os(visionOS)
import SwiftUI

extension LogLevel {
    /// Single-letter representation used in the row gutter and chip.
    var letter: String {
        switch self {
        case .debug:   return "D"
        case .info:    return "I"
        case .warning: return "W"
        case .error:   return "E"
        }
    }

    /// Human-readable name used in toolbars and pickers ("Debug", "Info", …).
    var displayName: String {
        switch self {
        case .debug:   return "Debug"
        case .info:    return "Info"
        case .warning: return "Warning"
        case .error:   return "Error"
        }
    }
}

/// Small letter chip (D/I/W/E) with severity-tinted background + border.
struct SeverityLetterView: View {
    let level: LogLevel
    var size: CGFloat = 14
    @Environment(\.forgeTheme) private var theme

    var body: some View {
        let sev = theme.severity[level] ?? theme.severity[.debug]!
        Text(level.letter)
            .font(theme.monoFont(size * 0.68, weight: .bold))
            .foregroundColor(sev.fg)
            .frame(width: size, height: size)
            .background(sev.bg)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(sev.bd, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
#endif
