#if canImport(SwiftUI)
import SwiftUI

public extension LogLevel {
    /// Color associated with this log level for UI display.
    var color: Color {
        switch self {
        case .debug:   return .gray
        case .info:    return .blue
        case .warning: return .orange
        case .error:   return .red
        }
    }

    /// Subtle background tint for color-coded row display.
    var backgroundTint: Color {
        switch self {
        case .debug:   return .gray.opacity(0.06)
        case .info:    return .blue.opacity(0.06)
        case .warning: return .orange.opacity(0.08)
        case .error:   return .red.opacity(0.08)
        }
    }
}
#endif
