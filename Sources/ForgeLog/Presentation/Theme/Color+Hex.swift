#if os(iOS) || os(visionOS)
import SwiftUI

public extension Color {
    /// `Color(hex: "#0B0B0E")` or `Color(hex: "#FFFFFF", opacity: 0.5)`.
    /// Accepts 3, 6, or 8-digit forms (last 2 digits = alpha when 8-digit).
    init(hex: String, opacity: Double = 1.0) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        _ = Scanner(string: cleaned).scanHexInt64(&value)
        let int = value

        let r, g, b, a: Double
        switch cleaned.count {
        case 3:
            r = Double((int >> 8) & 0xF) / 15.0
            g = Double((int >> 4) & 0xF) / 15.0
            b = Double(int & 0xF) / 15.0
            a = opacity
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
            a = opacity
        case 8:
            r = Double((int >> 24) & 0xFF) / 255.0
            g = Double((int >> 16) & 0xFF) / 255.0
            b = Double((int >> 8) & 0xFF) / 255.0
            a = Double(int & 0xFF) / 255.0 * opacity
        default:
            r = 1; g = 0; b = 1; a = 1 // visible magenta = "bad hex"
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
#endif
