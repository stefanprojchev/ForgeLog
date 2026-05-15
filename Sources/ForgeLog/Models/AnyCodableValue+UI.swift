import Foundation

public extension AnyCodableValue {
    /// Coarse classification used by UI to pick colors for parameter values.
    enum Kind: Sendable {
        case null, bool, number, string, array, dictionary
    }

    var kind: Kind {
        switch self {
        case .null:        return .null
        case .bool:        return .bool
        case .int, .double:return .number
        case .string:      return .string
        case .array:       return .array
        case .dictionary:  return .dictionary
        }
    }

    /// Display form: strings are quoted, `nil` is shown as `nil`, primitives as-is.
    /// Matches the handoff design's `LogValue.display` formatting so the existing
    /// row visuals stay consistent.
    var display: String {
        switch self {
        case .null:               return "nil"
        case .bool(let v):        return v ? "true" : "false"
        case .int(let v):         return String(v)
        case .double(let v):      return String(v)
        case .string(let v):      return "\"\(v)\""
        case .array, .dictionary: return description
        }
    }
}
