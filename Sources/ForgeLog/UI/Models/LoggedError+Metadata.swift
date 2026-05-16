#if os(iOS) || os(visionOS)
import Foundation

/// Log-side helpers that reconstruct a `LoggedError` from the
/// `AnyCodableValue` metadata `AnyCodableValue.from(_ error:)` flattens. Lives
/// in the UI layer because it's only used to drive log detail views — the
/// core `LoggedError` type lives in `Models/` and is consumed by
/// `NetworkLogEntry` from the ForgeNet target as well.
public extension LoggedError {
    /// Pulls a `LoggedError` out of metadata if the entry was logged with an
    /// `Error` (i.e. metadata has the `domain` / `code` shape produced by
    /// `AnyCodableValue.from(_ error:)`). Returns `nil` otherwise.
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
