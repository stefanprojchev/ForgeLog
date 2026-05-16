import Foundation
import ForgeLog

/// One captured HTTP request/response. Immutable, `Sendable`, `Codable`.
public struct NetworkLogEntry: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let timestamp: Date

    // MARK: Request
    public let method: HTTPMethod
    public let scheme: String          // "https", "wss"
    public let host: String
    public let path: String
    public let query: [String: String?]
    public let requestHeaders: [String: String]
    public let requestBytes: Int
    public let requestBody: Data?

    // MARK: Response
    public let status: Int?            // nil = failed before response
    public let statusText: String?
    public let responseHeaders: [String: String]
    public let responseBytes: Int
    public let responseBytesDecoded: Int?  // when gzip/deflate
    public let responseBody: Data?
    public let mime: String

    // MARK: Lifecycle
    public let durationMs: Int
    public let timing: NetworkTiming
    public let error: LoggedError?     // populated when URLSession returns Error
    public let redirectChain: [RedirectHop]?
    public let finalURL: String?
    public let streaming: Bool         // SSE or other long-lived transfer
    public let streamEventCount: Int?

    // MARK: Caller (best-effort link back to the originating call site)
    public let callerModule: String?
    public let callerClass: String?
    public let callerFunction: String?
    public let callerLine: Int?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        method: HTTPMethod,
        scheme: String,
        host: String,
        path: String,
        query: [String: String?] = [:],
        requestHeaders: [String: String] = [:],
        requestBytes: Int = 0,
        requestBody: Data? = nil,
        status: Int? = nil,
        statusText: String? = nil,
        responseHeaders: [String: String] = [:],
        responseBytes: Int = 0,
        responseBytesDecoded: Int? = nil,
        responseBody: Data? = nil,
        mime: String = "",
        durationMs: Int = 0,
        timing: NetworkTiming = NetworkTiming(),
        error: LoggedError? = nil,
        redirectChain: [RedirectHop]? = nil,
        finalURL: String? = nil,
        streaming: Bool = false,
        streamEventCount: Int? = nil,
        callerModule: String? = nil,
        callerClass: String? = nil,
        callerFunction: String? = nil,
        callerLine: Int? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
        self.scheme = scheme
        self.host = host
        self.path = path
        self.query = query
        self.requestHeaders = requestHeaders
        self.requestBytes = requestBytes
        self.requestBody = requestBody
        self.status = status
        self.statusText = statusText
        self.responseHeaders = responseHeaders
        self.responseBytes = responseBytes
        self.responseBytesDecoded = responseBytesDecoded
        self.responseBody = responseBody
        self.mime = mime
        self.durationMs = durationMs
        self.timing = timing
        self.error = error
        self.redirectChain = redirectChain
        self.finalURL = finalURL
        self.streaming = streaming
        self.streamEventCount = streamEventCount
        self.callerModule = callerModule
        self.callerClass = callerClass
        self.callerFunction = callerFunction
        self.callerLine = callerLine
    }

    // MARK: - Display helpers

    public var statusFamily: HTTPStatusFamily { HTTPStatusFamily.from(status: status) }
    public var failed: Bool { status == nil }
    public var isImage: Bool { mime.hasPrefix("image/") }
    public var isGzip: Bool {
        let encoding = responseHeaders["Content-Encoding"]?.lowercased() ?? ""
        return encoding.contains("gzip") || encoding.contains("br")
    }

    /// "15:29:38.044" — what list rows show in the time column.
    public var formattedTime: String {
        Self.timeFormatter.string(from: timestamp)
    }

    /// "180ms" or "1.23s" — adaptive precision.
    public var formattedDuration: String {
        if durationMs < 1000 { return "\(durationMs)ms" }
        return String(format: "%.2fs", Double(durationMs) / 1000.0)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
