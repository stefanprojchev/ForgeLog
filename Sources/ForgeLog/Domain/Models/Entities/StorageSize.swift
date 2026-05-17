import Foundation

/// A type-safe representation of a byte size for storage limits.
///
/// ```swift
/// LoggerConfiguration(maxTotalSize: .mb(50))
/// LoggerConfiguration(maxTotalSize: .gb(1))
/// ```
public enum StorageSize: Sendable, Equatable {
    case kb(Int)
    case mb(Int)
    case gb(Int)

    /// Converts to bytes (`Int64`).
    public var bytes: Int64 {
        switch self {
        case .kb(let count): return Int64(count) * 1_024
        case .mb(let count): return Int64(count) * 1_024 * 1_024
        case .gb(let count): return Int64(count) * 1_024 * 1_024 * 1_024
        }
    }
}
