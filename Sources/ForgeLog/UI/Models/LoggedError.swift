#if os(iOS) || os(visionOS)
import Foundation

/// Presentation snapshot of an `Error` derived from an entry's metadata.
/// `ForgeLog` flattens errors into `entry.metadata` via `AnyCodableValue.from(_ error:)`;
/// this view-side struct reconstructs the shape `LogDetailView` needs.
public struct LoggedError: Equatable, Sendable {
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
}

public extension LoggedError {
    /// Pulls a `LoggedError` out of metadata if the entry was logged with an
    /// `Error` (i.e. the metadata has the `domain` / `code` shape produced by
    /// `AnyCodableValue.from(_ error:)`).
    ///
    /// Returns `nil` for metadata that doesn't look like an error payload.
    init?(metadata: [String: AnyCodableValue]?) {
        guard let metadata,
              case .string(let domain) = metadata["domain"] ?? .null,
              case .int(let code) = metadata["code"] ?? .null
        else { return nil }

        let description: String = {
            if case .string(let s) = metadata["localizedDescription"] ?? .null { return s }
            return ""
        }()

        let userInfo: [String: AnyCodableValue] = {
            if case .dictionary(let dict) = metadata["userInfo"] ?? .null { return dict }
            return [:]
        }()

        self.init(
            domain: domain,
            code: code,
            description: description,
            userInfo: userInfo
        )
    }
}

public extension LogEntry {
    /// Returns a `LoggedError` if this entry's metadata represents an error,
    /// or `nil` for entries with plain metadata.
    var loggedError: LoggedError? {
        LoggedError(metadata: metadata)
    }

    /// Metadata minus the keys consumed by `loggedError` — what the
    /// "Parameters" section should display.
    var paramsMetadata: [String: AnyCodableValue]? {
        guard let metadata else { return nil }
        guard loggedError != nil else { return metadata }
        let consumed: Set<String> = ["domain", "code", "localizedDescription", "userInfo", "type", "underlyingError"]
        let rest = metadata.filter { !consumed.contains($0.key) }
        return rest.isEmpty ? nil : rest
    }
}
#endif
