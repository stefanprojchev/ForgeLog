import Foundation

/// A decorator provider that applies custom filters before forwarding
/// log entries to a wrapped provider.
///
/// ```swift
/// // Only persist logs from the "Payments" process to a separate disk provider
/// let paymentsProvider = FilteredLogProvider(
///     wrapping: DiskLogProvider(),
///     filter: { $0.processes.contains("Payments") }
/// )
///
/// // Only forward errors from a specific class
/// let errorProvider = FilteredLogProvider(
///     wrapping: PrintLogProvider(),
///     filter: { $0.className == "NetworkManager" && $0.level >= .error }
/// )
/// ```
public struct FilteredLogProvider: LogProviderProtocol {
    public let name: String
    public let minimumLevel: LogLevel
    private let wrappedProvider: LogProviderProtocol
    private let filter: @Sendable (LogEntry) -> Bool

    /// - Parameters:
    ///   - wrapping: The provider to forward matching entries to.
    ///   - minimumLevel: Minimum log level (applied before the custom filter).
    ///   - filter: A closure that returns `true` if the entry should be forwarded.
    public init(
        wrapping provider: LogProviderProtocol,
        minimumLevel: LogLevel = .debug,
        filter: @escaping @Sendable (LogEntry) -> Bool
    ) {
        self.wrappedProvider = provider
        self.minimumLevel = minimumLevel
        self.filter = filter
        self.name = "FilteredLogProvider(\(provider.name))"
    }

    // MARK: - Convenience: Single Value

    /// Forwards only entries matching a specific process.
    public init(wrapping provider: LogProviderProtocol, process: String) {
        self.init(wrapping: provider, filter: { $0.processes.contains(process) })
    }

    /// Forwards only entries from a specific class.
    public init(wrapping provider: LogProviderProtocol, className: String) {
        self.init(wrapping: provider, filter: { $0.className == className })
    }

    // MARK: - Convenience: Arrays

    /// Forwards entries matching any of the given processes. O(1) lookups.
    public init(wrapping provider: LogProviderProtocol, processes: [String]) {
        let processSet = Set(processes)
        self.init(wrapping: provider, filter: { entry in
            !entry.processes.isEmpty && !processSet.isDisjoint(with: entry.processes)
        })
    }

    /// Forwards entries from any of the given classes. O(1) lookups.
    public init(wrapping provider: LogProviderProtocol, classNames: [String]) {
        let classNameSet = Set(classNames)
        self.init(wrapping: provider, filter: { classNameSet.contains($0.className) })
    }

    /// Forwards entries matching any of the given processes **or** classes.
    /// Pass an empty array to skip either condition.
    public init(
        wrapping provider: LogProviderProtocol,
        processes: [String],
        classNames: [String]
    ) {
        let processSet = Set(processes)
        let classNameSet = Set(classNames)
        self.init(wrapping: provider, filter: { entry in
            if !processSet.isEmpty, !processSet.isDisjoint(with: entry.processes) {
                return true
            }
            if !classNameSet.isEmpty, classNameSet.contains(entry.className) {
                return true
            }
            return false
        })
    }

    // MARK: - Convenience: Minimum Level Only

    /// Forwards entries that meet a minimum level, with no additional filtering.
    public init(wrapping provider: LogProviderProtocol, level: LogLevel) {
        self.init(wrapping: provider, minimumLevel: level, filter: { _ in true })
    }

    // MARK: - LogProviderProtocol

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }
        guard filter(entry) else { return }
        wrappedProvider.log(entry)
    }
}
