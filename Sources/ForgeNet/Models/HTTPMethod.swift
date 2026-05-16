import Foundation

public enum HTTPMethod: String, Codable, Hashable, Sendable, CaseIterable {
    case GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS

    /// Order used by `MethodBadgeView` for color picking.
    public var order: Int {
        switch self {
        case .GET:                return 0
        case .POST:               return 1
        case .PUT:                return 2
        case .PATCH:              return 3
        case .DELETE:             return 4
        case .HEAD, .OPTIONS:     return 5
        }
    }
}

/// Family bucket for HTTP status codes. Drives the row gutter color, the
/// status cards row at the top of the list, and the status pill tint.
public enum HTTPStatusFamily: String, Codable, Hashable, Sendable, CaseIterable {
    case informational      // 1xx
    case success            // 2xx
    case redirect           // 3xx
    case clientError        // 4xx
    case serverError        // 5xx
    case failed             // network error — no status code at all

    public static func from(status: Int?) -> HTTPStatusFamily {
        guard let s = status else { return .failed }
        switch s {
        case 100..<200: return .informational
        case 200..<300: return .success
        case 300..<400: return .redirect
        case 400..<500: return .clientError
        case 500..<600: return .serverError
        default:        return .failed
        }
    }

    public var displayName: String {
        switch self {
        case .informational: return "1xx"
        case .success:       return "2xx"
        case .redirect:      return "3xx"
        case .clientError:   return "4xx"
        case .serverError:   return "5xx"
        case .failed:        return "Failed"
        }
    }
}
