#if os(iOS) || os(visionOS)
import Foundation

/// All filter state for the log list. Holds sets of strings because modules,
/// classes and processes are themselves strings.
public struct FilterState: Equatable, Sendable {
    public var level: LogLevel? = nil
    public var modules: Set<String> = []
    public var processes: Set<String> = []
    public var classes: Set<String> = []
    public var dateRange: ClosedRange<Date>? = nil
    public var query: String = ""

    public init() {}

    /// `true` when any filter is non-default. Drives the red "clear" X button.
    public var hasActiveFilters: Bool {
        level != nil ||
        !modules.isEmpty ||
        !processes.isEmpty ||
        !classes.isEmpty ||
        dateRange != nil ||
        !query.isEmpty
    }

    /// Wipe everything back to default state.
    public mutating func clear() {
        self = FilterState()
    }

    /// Wipe just the bottom-row filters (Module / Process / Class). Keeps
    /// level + search intact.
    public mutating func clearChipFilters() {
        modules = []
        processes = []
        classes = []
    }

    /// Returns `true` when `entry` passes all active filters.
    public func matches(_ entry: LogEntry) -> Bool {
        if let level, entry.level != level { return false }
        if !modules.isEmpty {
            guard let m = entry.module, modules.contains(m) else { return false }
        }
        if !processes.isEmpty, !processes.contains(where: entry.processes.contains) { return false }
        if !classes.isEmpty, !classes.contains(entry.className) { return false }
        if let dateRange, !dateRange.contains(entry.timestamp) { return false }
        if !query.isEmpty {
            let q = query.lowercased()
            if !entry.message.lowercased().contains(q),
               !entry.className.lowercased().contains(q),
               !(entry.module?.lowercased().contains(q) ?? false) {
                return false
            }
        }
        return true
    }
}
#endif
