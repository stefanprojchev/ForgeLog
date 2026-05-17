import Foundation

/// All filter state for the network list. Sibling of ForgeLog's `FilterState`
/// but with HTTP-specific dimensions (status family, methods, hosts, callers).
public struct NetworkFilterState: Equatable, Sendable {
    public var statusFamily: HTTPStatusFamily? = nil   // nil = "All"
    public var methods: Set<HTTPMethod> = []
    public var hosts: Set<String> = []
    public var callers: Set<String> = []               // by module name
    public var dateRange: ClosedRange<Date>? = nil
    public var query: String = ""

    public init() {}

    public var hasActiveFilters: Bool {
        statusFamily != nil ||
        !methods.isEmpty ||
        !hosts.isEmpty ||
        !callers.isEmpty ||
        dateRange != nil ||
        !query.isEmpty
    }

    public mutating func clear() { self = NetworkFilterState() }

    /// Wipes the chip-row filters (Method / Host / Caller) but keeps the
    /// status family selection and search query intact.
    public mutating func clearChipFilters() {
        methods = []
        hosts = []
        callers = []
    }

    public func matches(_ entry: NetworkLogEntry) -> Bool {
        if let f = statusFamily, entry.statusFamily != f { return false }
        if !methods.isEmpty, !methods.contains(entry.method) { return false }
        if !hosts.isEmpty, !hosts.contains(entry.host) { return false }
        if !callers.isEmpty {
            guard let m = entry.callerModule, callers.contains(m) else { return false }
        }
        if let r = dateRange, !r.contains(entry.timestamp) { return false }
        if !query.isEmpty {
            let q = query.lowercased()
            if !entry.path.lowercased().contains(q),
               !entry.host.lowercased().contains(q),
               !(entry.callerClass ?? "").lowercased().contains(q) {
                return false
            }
        }
        return true
    }
}
