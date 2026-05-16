import Foundation
import ForgeLog

/// `URLSession` instrumentation. Drop a `ForgeNetURLProtocol` into your
/// session's `protocolClasses` and every request fires through the store.
///
/// ```swift
/// let config = URLSessionConfiguration.default
/// ForgeNet.install(into: config)
/// let session = URLSession(configuration: config)
/// ```
///
/// For `URLSession.shared` and SwiftUI's `AsyncImage`-style implicit sessions
/// register globally via `URLProtocol.registerClass(_:)`. That's a process-
/// wide side effect — only enable in DEBUG / TESTFLIGHT builds.
public final class ForgeNetURLProtocol: URLProtocol, @unchecked Sendable {

    private static let handledKey = "ForgeNetURLProtocol.handled"
    private var currentTask: URLSessionDataTask?   // not `task` — `URLProtocol.task` is a public stored property and Swift treats `private var task` as an attempted override.
    private var receivedData = Data()
    private var receivedResponse: HTTPURLResponse?
    private var startDate = Date()
    private var capturedMetrics: URLSessionTaskMetrics?  // same shadow concern for `metrics`

    // MARK: - URLProtocol

    public override class func canInit(with request: URLRequest) -> Bool {
        // Don't re-enter ourselves.
        if URLProtocol.property(forKey: handledKey, in: request) != nil { return false }
        // Only HTTP(S).
        guard let scheme = request.url?.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    public override func startLoading() {
        guard let mutable = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutable)

        startDate = Date()
        let session = URLSession(configuration: .default,
                                 delegate: SessionDelegate(owner: self),
                                 delegateQueue: nil)
        currentTask = session.dataTask(with: mutable as URLRequest)
        currentTask?.resume()
    }

    public override func stopLoading() {
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: - Delegate proxy

    private final class SessionDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
        weak var owner: ForgeNetURLProtocol?   // weak vars must be `var` — hence @unchecked Sendable on the class.
        init(owner: ForgeNetURLProtocol) { self.owner = owner }

        func urlSession(_ session: URLSession,
                        dataTask: URLSessionDataTask,
                        didReceive response: URLResponse,
                        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            owner?.receivedResponse = response as? HTTPURLResponse
            if let owner {
                owner.client?.urlProtocol(owner, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            completionHandler(.allow)
        }

        func urlSession(_ session: URLSession,
                        dataTask: URLSessionDataTask,
                        didReceive data: Data) {
            owner?.receivedData.append(data)
            if let owner {
                owner.client?.urlProtocol(owner, didLoad: data)
            }
        }

        func urlSession(_ session: URLSession,
                        task: URLSessionTask,
                        didFinishCollecting metrics: URLSessionTaskMetrics) {
            owner?.capturedMetrics = metrics
        }

        func urlSession(_ session: URLSession,
                        task: URLSessionTask,
                        didCompleteWithError error: Error?) {
            guard let owner = owner else { return }
            owner.recordEntry(error: error)
            if let error {
                owner.client?.urlProtocol(owner, didFailWithError: error)
            } else {
                owner.client?.urlProtocolDidFinishLoading(owner)
            }
        }
    }

    // MARK: - Build NetworkLogEntry

    private func recordEntry(error: Error?) {
        let url = request.url
        let method = HTTPMethod(rawValue: request.httpMethod ?? "GET") ?? .GET
        let scheme = url?.scheme ?? ""
        let host = url?.host ?? ""
        let path = url?.path ?? ""

        var query: [String: String?] = [:]
        if let url, let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            for item in comps.queryItems ?? [] { query[item.name] = item.value }
        }

        let reqHeaders = request.allHTTPHeaderFields ?? [:]
        let reqBody = request.httpBody
        let reqBytes = (reqBody?.count ?? 0) + headerBytes(reqHeaders)

        let status = receivedResponse?.statusCode
        let statusText = status.map { HTTPURLResponse.localizedString(forStatusCode: $0) }
        let resHeaders = (receivedResponse?.allHeaderFields as? [String: String]) ?? [:]
        let resBytes = receivedData.count + headerBytes(resHeaders)
        let mime = receivedResponse?.mimeType ?? ""

        let duration = Int(Date().timeIntervalSince(startDate) * 1000)
        let timing = capturedMetrics.map(NetworkTiming.init(from:)) ?? NetworkTiming()

        let loggedError = error.map(LoggedError.init)

        // Respect capture toggles + max body size.
        let config = ForgeNet.shared.configuration
        let truncatedReqBody = config.captureRequestBody
            ? truncate(reqBody, to: config.maxBodyBytes)
            : nil
        let truncatedResBody = config.captureResponseBody
            ? truncate(receivedData, to: config.maxBodyBytes)
            : nil

        let entry = NetworkLogEntry(
            timestamp: startDate,
            method: method,
            scheme: scheme,
            host: host,
            path: path,
            query: query,
            requestHeaders: ForgeNet.shared.redact(headers: reqHeaders),
            requestBytes: reqBytes,
            requestBody: truncatedReqBody,
            status: status,
            statusText: statusText,
            responseHeaders: ForgeNet.shared.redact(headers: resHeaders),
            responseBytes: resBytes,
            responseBytesDecoded: nil,
            responseBody: truncatedResBody,
            mime: mime,
            durationMs: duration,
            timing: timing,
            error: loggedError,
            redirectChain: nil,
            finalURL: receivedResponse?.url?.absoluteString,
            streaming: mime == "text/event-stream",
            streamEventCount: nil
        )

        Task { @MainActor in
            ForgeNet.shared.store?.append(entry)
        }
    }

    private func headerBytes(_ headers: [String: String]) -> Int {
        // "k: v\r\n" — close enough for sizing.
        headers.reduce(0) { $0 + $1.key.utf8.count + $1.value.utf8.count + 4 }
    }

    private func truncate(_ data: Data?, to maxBytes: Int) -> Data? {
        guard let data, !data.isEmpty else { return nil }
        if data.count <= maxBytes { return data }
        return data.prefix(maxBytes)
    }
}
