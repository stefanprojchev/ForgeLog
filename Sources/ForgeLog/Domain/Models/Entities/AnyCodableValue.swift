import Foundation

/// A type-erased Codable value that can represent JSON primitives,
/// arrays, and dictionaries. Used for structured log metadata.
public enum AnyCodableValue: Codable, Sendable, Hashable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AnyCodableValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(value)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):     try container.encode(value)
        case .int(let value):        try container.encode(value)
        case .double(let value):     try container.encode(value)
        case .bool(let value):       try container.encode(value)
        case .array(let value):      try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        case .null:                  try container.encodeNil()
        }
    }

    public var description: String {
        switch self {
        case .string(let value):     return value
        case .int(let value):        return "\(value)"
        case .double(let value):     return "\(value)"
        case .bool(let value):       return value ? "true" : "false"
        case .array(let items):
            return "[" + items.map(\.description).joined(separator: ", ") + "]"
        case .dictionary(let dict):
            return "{" + dict.keys.sorted().map { "\($0): \(dict[$0]!.description)" }.joined(separator: ", ") + "}"
        case .null:                  return "null"
        }
    }

    /// Formats a metadata dictionary as a readable flat string for log output.
    /// Produces output like: `code=404, type=URLError, userInfo={key1: val1, key2: val2}`
    public static func plainText(from metadata: [String: AnyCodableValue]) -> String {
        metadata.keys.sorted().map { key in
            "\(key)=\(metadata[key]!.description)"
        }.joined(separator: ", ")
    }

    /// Converts any JSON-compatible Foundation object (from JSONSerialization)
    /// into an `AnyCodableValue` tree.
    static func from(jsonObject: Any) -> AnyCodableValue {
        switch jsonObject {
        case let string as String:
            return .string(string)
        case let number as NSNumber:
            // CFBoolean check to distinguish Bool from Int/Double
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            } else if number.doubleValue == Double(number.intValue) {
                return .int(number.intValue)
            } else {
                return .double(number.doubleValue)
            }
        case let array as [Any]:
            return .array(array.map { from(jsonObject: $0) })
        case let dict as [String: Any]:
            return .dictionary(dict.mapValues { from(jsonObject: $0) })
        case is NSNull:
            return .null
        default:
            return .string(String(describing: jsonObject))
        }
    }
}

public extension AnyCodableValue {
    /// Creates metadata from any `Encodable` value by encoding to JSON
    /// and then parsing back into `AnyCodableValue`.
    ///
    /// `NSObject` subclasses can cause stack overflows in `JSONEncoder` due to
    /// circular references or complex inheritance. Stack overflows are not
    /// catchable by `try?`, so we guard upfront with `String(describing:)`.
    static func from<T: Encodable>(_ value: T) -> [String: AnyCodableValue] {
        if value is NSObject {
            return ["value": .string(String(describing: value))]
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return ["value": .string(String(describing: value))]
        }

        switch from(jsonObject: jsonObject) {
        case .dictionary(let dict):
            return dict
        case let other:
            return ["value": other]
        }
    }

    /// Creates metadata from an array of `Encodable` values.
    static func from<T: Encodable>(_ values: [T]) -> [String: AnyCodableValue] {
        let items = values.map { item -> AnyCodableValue in
            if item is NSObject {
                return .string(String(describing: item))
            }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? encoder.encode(item),
                  let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
                return .string(String(describing: item))
            }
            return AnyCodableValue.from(jsonObject: jsonObject)
        }
        return ["items": .array(items), "count": .int(values.count)]
    }

    /// Creates metadata from an `Error`, extracting useful debugging info.
    /// - SeeAlso: `Error.asMetadata` for a convenient extension.
    static func from(_ error: Error) -> [String: AnyCodableValue] {
        var dict: [String: AnyCodableValue] = [
            "localizedDescription": .string(error.localizedDescription),
            "type": .string(String(describing: type(of: error)))
        ]

        let nsError = error as NSError
        dict["domain"] = .string(nsError.domain)
        dict["code"] = .int(nsError.code)

        if !nsError.userInfo.isEmpty {
            var userInfoDict: [String: AnyCodableValue] = [:]
            for (key, value) in nsError.userInfo {
                userInfoDict[key] = .string(String(describing: value))
            }
            dict["userInfo"] = .dictionary(userInfoDict)
        }

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            dict["underlyingError"] = .string(underlying.localizedDescription)
        }

        return dict
    }

    /// Creates metadata from an array of `Error` values.
    static func from(_ errors: [Error]) -> [String: AnyCodableValue] {
        let items = errors.map { AnyCodableValue.dictionary(from($0)) }
        return ["errors": .array(items), "count": .int(errors.count)]
    }
}

public extension Error {
    /// Converts this error into structured metadata for logging.
    ///
    /// ```swift
    /// ForgeLog.shared.error("Something failed", metadata: error.asMetadata)
    /// ```
    var asMetadata: [String: AnyCodableValue] {
        AnyCodableValue.from(self)
    }
}

public extension Encodable {
    /// Converts this `Encodable` value into structured metadata for logging.
    ///
    /// ```swift
    /// ForgeLog.shared.info("Post updated", metadata: post.asLogMetadata)
    /// // Combine: error.asMetadata + post.asLogMetadata
    /// ```
    var asLogMetadata: [String: AnyCodableValue] {
        AnyCodableValue.from(self)
    }
}

public extension Dictionary where Key == String, Value == AnyCodableValue {
    /// Merges two metadata dictionaries. Right-hand side values win on key conflicts.
    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.merging(rhs) { _, new in new }
    }
}
