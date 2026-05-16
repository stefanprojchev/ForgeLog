import Foundation

/// Snapshot of an `Error` at the point of logging or network capture.
///
/// We can't store `Error` directly — it's not `Codable`, and `NSError.userInfo`
/// is `[String: Any]` which doesn't survive `JSONEncoder`. So we lossily
/// convert to a `[String: AnyCodableValue]` once at capture time.
///
/// Cross-platform value type with no SwiftUI dependency, so the URLProtocol
/// capture layer (`ForgeNet`) and the log metadata flatten path can both
/// produce these directly.
public struct LoggedError: Codable, Hashable, Sendable {
    public let domain: String
    public let code: Int
    public let description: String
    public let userInfo: [String: AnyCodableValue]

    public init(
        domain: String,
        code: Int,
        description: String,
        userInfo: [String: AnyCodableValue] = [:]
    ) {
        self.domain = domain
        self.code = code
        self.description = description
        self.userInfo = userInfo
    }

    /// Lossily converts any `Error` into a `LoggedError`. Works for `NSError`,
    /// `LocalizedError`, and plain Swift errors. Underlying errors (under
    /// `NSUnderlyingErrorKey`) are dropped to avoid infinite recursion — log
    /// them separately if you need them.
    public init(_ error: Error) {
        let ns = error as NSError
        self.domain = ns.domain
        self.code = ns.code

        if let local = (error as? LocalizedError)?.errorDescription {
            self.description = local
        } else {
            self.description = ns.localizedDescription
        }

        var converted: [String: AnyCodableValue] = [:]
        for (key, value) in ns.userInfo {
            if value is Error { continue }
            converted[key] = Self.encodeUserInfoValue(value)
        }
        self.userInfo = converted
    }

    /// Mirrors `AnyCodableValue.init(_:)` for JSON-shaped values but doesn't
    /// drag in `JSONSerialization` for the common-case strings/numbers/URLs.
    private static func encodeUserInfoValue(_ value: Any) -> AnyCodableValue {
        switch value {
        case let s as String:        return .string(s)
        case let b as Bool:          return .bool(b)
        case let i as Int:           return .int(i)
        case let d as Double:        return .double(d)
        case let f as Float:         return .double(Double(f))
        case let url as URL:         return .string(url.absoluteString)
        case is NSNull:              return .null
        case let n as NSNumber:
            // Distinguish Bool / Int / Double the same way AnyCodableValue does.
            if CFGetTypeID(n) == CFBooleanGetTypeID() { return .bool(n.boolValue) }
            if n.doubleValue == Double(n.intValue) { return .int(n.intValue) }
            return .double(n.doubleValue)
        default:
            return .string(String(describing: value))
        }
    }
}
