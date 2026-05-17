import Foundation

/// Per-phase wall-clock durations for a single request. All values are
/// milliseconds. Zero means cached or not applicable (e.g. `dnsMs=0` when the
/// host was already resolved).
public struct NetworkTiming: Codable, Hashable, Sendable {
    public var dnsMs: Int
    public var tcpMs: Int
    public var tlsMs: Int
    public var ttfbMs: Int          // request sent → first byte
    public var transferMs: Int      // body download

    public init(dnsMs: Int = 0, tcpMs: Int = 0, tlsMs: Int = 0, ttfbMs: Int = 0, transferMs: Int = 0) {
        self.dnsMs = dnsMs
        self.tcpMs = tcpMs
        self.tlsMs = tlsMs
        self.ttfbMs = ttfbMs
        self.transferMs = transferMs
    }

    public var totalMs: Int { dnsMs + tcpMs + tlsMs + ttfbMs + transferMs }

    /// Build from `URLSessionTaskMetrics`. Picks the first transaction; for
    /// multi-hop URLSessions the redirect chain is captured separately on
    /// `NetworkLogEntry`.
    public init(from metrics: URLSessionTaskMetrics) {
        var dns = 0, tcp = 0, tls = 0, ttfb = 0, transfer = 0
        if let m = metrics.transactionMetrics.first {
            if let s = m.domainLookupStartDate, let e = m.domainLookupEndDate {
                dns = Int(e.timeIntervalSince(s) * 1000)
            }
            if let s = m.connectStartDate, let e = m.connectEndDate {
                tcp = Int(e.timeIntervalSince(s) * 1000)
            }
            if let s = m.secureConnectionStartDate, let e = m.secureConnectionEndDate {
                tls = Int(e.timeIntervalSince(s) * 1000)
            }
            if let s = m.requestEndDate, let e = m.responseStartDate {
                ttfb = Int(e.timeIntervalSince(s) * 1000)
            }
            if let s = m.responseStartDate, let e = m.responseEndDate {
                transfer = Int(e.timeIntervalSince(s) * 1000)
            }
        }
        self.init(dnsMs: dns, tcpMs: tcp, tlsMs: tls, ttfbMs: ttfb, transferMs: transfer)
    }
}

/// One hop in a redirect chain. The final hop has `to == nil`.
public struct RedirectHop: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let status: Int
    public let url: String
    public let to: String?

    public init(id: UUID = UUID(), status: Int, url: String, to: String? = nil) {
        self.id = id
        self.status = status
        self.url = url
        self.to = to
    }
}
