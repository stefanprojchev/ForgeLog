#if os(iOS) || os(visionOS)
import SwiftUI
import ForgeLog

/// Network-specific theme helpers. We don't add new fields to `ForgeLogTheme`
/// — network views look up the existing severity tokens via these computed
/// helpers, so the dark/light palette stays in one place.
public extension ForgeLogTheme {
    struct MethodStyle: Sendable {
        public var fg: Color
        public var bg: Color
        public var bd: Color

        public init(fg: Color, bg: Color, bd: Color) {
            self.fg = fg
            self.bg = bg
            self.bd = bd
        }
    }

    /// Color set for an HTTP method. Reuses the severity tokens so the network
    /// view inherits the dark/light palette automatically.
    func methodStyle(_ method: HTTPMethod) -> MethodStyle {
        switch method {
        case .GET, .HEAD, .OPTIONS:
            let s = severity[.info]!
            return .init(fg: s.fg, bg: s.bg, bd: s.bd)
        case .POST:
            // POST = green (success). Hand-derive so it matches the LIVE pill.
            return .init(fg: success,
                         bg: success.opacity(0.10),
                         bd: successBd)
        case .PUT, .PATCH:
            let s = severity[.warning]!
            return .init(fg: s.fg, bg: s.bg, bd: s.bd)
        case .DELETE:
            let s = severity[.error]!
            return .init(fg: s.fg, bg: s.bg, bd: s.bd)
        }
    }

    /// Color set for a status code. 2xx / 1xx → info blue; 3xx → debug
    /// gray; 4xx → warning amber; 5xx + failed → error red.
    func statusStyle(_ status: Int?) -> Severity {
        switch HTTPStatusFamily.from(status: status) {
        case .success, .informational: return severity[.info]!
        case .redirect:                return severity[.debug]!
        case .clientError:             return severity[.warning]!
        case .serverError, .failed:    return severity[.error]!
        }
    }
}
#endif
