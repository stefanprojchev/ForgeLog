import Foundation

/// Top-level namespace for the network capture layer. Symmetric with
/// `ForgeLog` for diagnostic logs.
///
/// ```swift
/// ForgeNet.start(configuration: .default)
///
/// // Option 1: instrument your own session
/// let config = URLSessionConfiguration.default
/// ForgeNet.install(into: config)
/// let session = URLSession(configuration: config)
///
/// // Option 2: hook everything (DEBUG only — registers process-wide)
/// #if DEBUG
/// ForgeNet.installGlobally()
/// #endif
///
/// // Present:
/// NavigationStack { ForgeNetView() }
/// ```
public final class ForgeNet: @unchecked Sendable {

    public static let shared = ForgeNet()
    private init() {}

    @MainActor public private(set) var store: NetworkLogStore?
    private(set) var configuration: ForgeNetConfiguration = .default

    @MainActor
    public static func start(configuration: ForgeNetConfiguration = .default) {
        shared.configuration = configuration
        if shared.store == nil {
            shared.store = NetworkLogStore(configuration: configuration)
        }
    }

    /// Add ForgeNet instrumentation to a specific `URLSessionConfiguration`.
    /// Idempotent — adding twice does nothing.
    public static func install(into config: URLSessionConfiguration) {
        var protocols = config.protocolClasses ?? []
        if !protocols.contains(where: { $0 == ForgeNetURLProtocol.self }) {
            protocols.insert(ForgeNetURLProtocol.self, at: 0)
            config.protocolClasses = protocols
        }
    }

    /// Register globally — instruments `URLSession.shared` and any session
    /// that doesn't override `protocolClasses`. Process-wide side effect;
    /// only enable in DEBUG builds.
    public static func installGlobally() {
        URLProtocol.registerClass(ForgeNetURLProtocol.self)
    }

    public static func uninstallGlobally() {
        URLProtocol.unregisterClass(ForgeNetURLProtocol.self)
    }

    // MARK: - Redaction

    /// Strips sensitive headers based on the configuration. Keys are preserved
    /// (so the detail view can show that a header WAS present) but values are
    /// replaced with `<redacted>`.
    func redact(headers: [String: String]) -> [String: String] {
        guard configuration.autoRedactAuthHeaders else { return headers }
        let sensitive: Set<String> = [
            "authorization", "cookie", "set-cookie",
            "x-api-key", "x-auth-token", "proxy-authorization",
        ]
        var out: [String: String] = [:]
        for (key, value) in headers {
            out[key] = sensitive.contains(key.lowercased()) ? "<redacted>" : value
        }
        return out
    }
}

/// Capture configuration. Defaults match what the Settings sheet shows.
public struct ForgeNetConfiguration: Sendable {
    public var inMemoryLimit: Int
    public var captureRequestBody: Bool
    public var captureResponseBody: Bool
    public var maxBodyBytes: Int            // truncate beyond this
    public var autoRedactAuthHeaders: Bool
    public var autoRedactSensitiveBody: Bool
    public var slowRequestThresholdMs: Int  // > threshold → row tints amber

    public init(
        inMemoryLimit: Int = 5_000,
        captureRequestBody: Bool = true,
        captureResponseBody: Bool = true,
        maxBodyBytes: Int = 1_048_576,
        autoRedactAuthHeaders: Bool = true,
        autoRedactSensitiveBody: Bool = true,
        slowRequestThresholdMs: Int = 1_000
    ) {
        self.inMemoryLimit = inMemoryLimit
        self.captureRequestBody = captureRequestBody
        self.captureResponseBody = captureResponseBody
        self.maxBodyBytes = maxBodyBytes
        self.autoRedactAuthHeaders = autoRedactAuthHeaders
        self.autoRedactSensitiveBody = autoRedactSensitiveBody
        self.slowRequestThresholdMs = slowRequestThresholdMs
    }

    public static let `default` = ForgeNetConfiguration()
}
