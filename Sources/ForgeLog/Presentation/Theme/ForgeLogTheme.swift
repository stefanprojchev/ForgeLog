#if os(iOS) || os(visionOS)
import SwiftUI

/// Value-type design tokens for ForgeLog. Use `.dark` / `.light` static
/// instances, or build a custom theme by mutating fields after copy.
///
/// Access through `@Environment(\.forgeTheme)` in views — `ForgeLogView`
/// injects the right one based on the user's theme setting + system appearance.
public struct ForgeLogTheme: Sendable {
    public enum Mode: Sendable { case dark, light }
    public var mode: Mode

    // Surfaces
    public var bg: Color
    public var bgAlt: Color
    public var surface: Color
    public var surfaceHi: Color
    public var surface2: Color

    // Strokes
    public var border: Color
    public var borderHi: Color

    // Text
    public var text1: Color   // primary
    public var text2: Color   // secondary
    public var text3: Color   // tertiary
    public var text4: Color   // quaternary

    // Roles
    public var accent: Color
    public var accentBg: Color
    public var accentBd: Color
    public var danger: Color
    public var success: Color
    public var successBd: Color

    public var sheetDim: Color

    public var severity: [LogLevel: Severity]
    public var allSeverity: Severity

    public var moduleColors: [String: Color]

    public var mono: MonoFont
    public var sans: SansFont

    public enum MonoFont: Sendable { case jetBrainsMono, sfMono, system }
    public enum SansFont: Sendable { case system }

    /// Per-severity color block.
    public struct Severity: Sendable {
        public var fg: Color
        public var dim: Color
        public var bg: Color
        public var bd: Color

        public init(fg: Color, dim: Color, bg: Color, bd: Color) {
            self.fg = fg; self.dim = dim; self.bg = bg; self.bd = bd
        }
    }

    /// Returns the explicit mapping if present, otherwise a deterministic
    /// accent picked from the palette by hashing the module name.
    public func moduleColor(for module: String) -> Color {
        if let explicit = moduleColors[module] { return explicit }
        let palette: [Color] = mode == .light ? [
            Color(hex: "#7B4FCC"), Color(hex: "#0058D8"), Color(hex: "#0E8C44"),
            Color(hex: "#A45F00"), Color(hex: "#C73E80"), Color(hex: "#3F4A60"),
        ] : [
            Color(hex: "#B68CFF"), Color(hex: "#5BA8FF"), Color(hex: "#3ED07A"),
            Color(hex: "#FFB547"), Color(hex: "#FF7AB8"), Color(hex: "#8E9AB0"),
        ]
        var hash = 5381
        for byte in module.utf8 { hash = ((hash << 5) &+ hash) &+ Int(byte) }
        return palette[abs(hash) % palette.count]
    }
}

// MARK: - Static instances

public extension ForgeLogTheme {
    static let dark = ForgeLogTheme(
        mode: .dark,
        bg:        Color(hex: "#0B0B0E"),
        bgAlt:     Color(hex: "#0E0E12"),
        surface:   Color(hex: "#15151A"),
        surfaceHi: Color(hex: "#1C1C22"),
        surface2:  Color(hex: "#222229"),
        border:    Color.white.opacity(0.07),
        borderHi:  Color.white.opacity(0.14),
        text1:     Color(hex: "#F2F2F5"),
        text2:     Color(hex: "#EBEBF5").opacity(0.62),
        text3:     Color(hex: "#EBEBF5").opacity(0.32),
        text4:     Color(hex: "#EBEBF5").opacity(0.18),
        accent:    Color(hex: "#5BA8FF"),
        accentBg:  Color(hex: "#5BA8FF").opacity(0.12),
        accentBd:  Color(hex: "#5BA8FF").opacity(0.32),
        danger:    Color(hex: "#FF5C5C"),
        success:   Color(hex: "#3ED07A"),
        successBd: Color(hex: "#3ED07A").opacity(0.55),
        sheetDim:  Color.black.opacity(0.42),
        severity: [
            .debug:   .init(fg: Color(hex: "#8E9AB0"), dim: Color(hex: "#5C6577"),
                            bg: Color(hex: "#8E9AB0").opacity(0.10),
                            bd: Color(hex: "#8E9AB0").opacity(0.28)),
            .info:    .init(fg: Color(hex: "#5BA8FF"), dim: Color(hex: "#3B7AC1"),
                            bg: Color(hex: "#5BA8FF").opacity(0.10),
                            bd: Color(hex: "#5BA8FF").opacity(0.30)),
            .warning: .init(fg: Color(hex: "#FFB547"), dim: Color(hex: "#B97E22"),
                            bg: Color(hex: "#FFB547").opacity(0.10),
                            bd: Color(hex: "#FFB547").opacity(0.32)),
            .error:   .init(fg: Color(hex: "#FF6B6B"), dim: Color(hex: "#B23939"),
                            bg: Color(hex: "#FF6B6B").opacity(0.10),
                            bd: Color(hex: "#FF6B6B").opacity(0.35)),
        ],
        allSeverity: .init(
            fg: Color(hex: "#F2F2F5"),
            dim: Color(hex: "#F2F2F5"),
            bg: Color.white.opacity(0.04),
            bd: Color.white.opacity(0.10)
        ),
        moduleColors: [
            "ForgeLog": Color(hex: "#8E9AB0"),
        ],
        mono: .jetBrainsMono,
        sans: .system
    )

    static let light = ForgeLogTheme(
        mode: .light,
        bg:        Color(hex: "#F6F5F1"),
        bgAlt:     Color(hex: "#EFEEE9"),
        surface:   Color(hex: "#FFFFFF"),
        surfaceHi: Color(hex: "#FAFAF6"),
        surface2:  Color(hex: "#EFEEE9"),
        border:    Color.black.opacity(0.09),
        borderHi:  Color.black.opacity(0.16),
        text1:     Color(hex: "#0D0D10"),
        text2:     Color(hex: "#26262A").opacity(0.68),
        text3:     Color(hex: "#26262A").opacity(0.44),
        text4:     Color(hex: "#26262A").opacity(0.22),
        accent:    Color(hex: "#0058D8"),
        accentBg:  Color(hex: "#0058D8").opacity(0.10),
        accentBd:  Color(hex: "#0058D8").opacity(0.30),
        danger:    Color(hex: "#D32F2F"),
        success:   Color(hex: "#0E8C44"),
        successBd: Color(hex: "#0E8C44").opacity(0.35),
        sheetDim:  Color.black.opacity(0.18),
        severity: [
            .debug:   .init(fg: Color(hex: "#5C6B85"), dim: Color(hex: "#3F4A60"),
                            bg: Color(hex: "#5C6B85").opacity(0.08),
                            bd: Color(hex: "#5C6B85").opacity(0.26)),
            .info:    .init(fg: Color(hex: "#0058D8"), dim: Color(hex: "#003F9E"),
                            bg: Color(hex: "#0058D8").opacity(0.07),
                            bd: Color(hex: "#0058D8").opacity(0.28)),
            .warning: .init(fg: Color(hex: "#A45F00"), dim: Color(hex: "#6F4100"),
                            bg: Color(hex: "#A45F00").opacity(0.09),
                            bd: Color(hex: "#A45F00").opacity(0.28)),
            .error:   .init(fg: Color(hex: "#C7302C"), dim: Color(hex: "#922222"),
                            bg: Color(hex: "#C7302C").opacity(0.07),
                            bd: Color(hex: "#C7302C").opacity(0.30)),
        ],
        allSeverity: .init(
            fg: Color(hex: "#0D0D10"),
            dim: Color(hex: "#0D0D10"),
            bg: Color.black.opacity(0.05),
            bd: Color.black.opacity(0.14)
        ),
        moduleColors: [
            "ForgeLog": Color(hex: "#3F4A60"),
        ],
        mono: .jetBrainsMono,
        sans: .system
    )
}

// MARK: - Environment plumbing

private struct ForgeThemeKey: EnvironmentKey {
    static let defaultValue: ForgeLogTheme = .dark
}

public extension EnvironmentValues {
    var forgeTheme: ForgeLogTheme {
        get { self[ForgeThemeKey.self] }
        set { self[ForgeThemeKey.self] = newValue }
    }
}

// MARK: - Font helpers

public extension ForgeLogTheme {
    /// Monospaced font at a given size + weight. Falls back from
    /// JetBrains Mono → SF Mono → system mono automatically.
    func monoFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch mono {
        case .jetBrainsMono:
            return Font.custom("JetBrainsMono-Regular", size: size).weight(weight)
        case .sfMono, .system:
            return Font.system(size: size, weight: weight, design: .monospaced)
        }
    }

    func sansFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .default)
    }
}
#endif
