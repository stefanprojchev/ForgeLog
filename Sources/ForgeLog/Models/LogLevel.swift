import Foundation

/// Severity of a log entry. Lower raw values are less severe.
public enum LogLevel: Int, Codable, Sendable, Comparable, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public var label: String {
        switch self {
        case .debug:   return "DEBUG"
        case .info:    return "INFO"
        case .warning: return "WARNING"
        case .error:   return "ERROR"
        }
    }

    public var emoji: String {
        switch self {
        case .debug:   return "🔍"
        case .info:    return "ℹ️"
        case .warning: return "⚠️"
        case .error:   return "🔴"
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

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
