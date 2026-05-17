import Foundation

/// A type-safe representation of a time duration for log retention.
///
/// Use this instead of raw `TimeInterval` values to make log retention
/// configuration self-documenting:
/// ```swift
/// LoggerConfiguration(maxAge: .days(30))
/// LoggerConfiguration(maxAge: .weeks(2))
/// ```
public enum LogAge: Sendable, Equatable {
    case hours(Int)
    case days(Int)
    case weeks(Int)
    case months(Int)

    /// Converts to `TimeInterval` (seconds).
    public var timeInterval: TimeInterval {
        switch self {
        case .hours(let count):   return TimeInterval(count) * 3_600
        case .days(let count):    return TimeInterval(count) * 86_400
        case .weeks(let count):   return TimeInterval(count) * 604_800
        case .months(let count):  return TimeInterval(count) * 2_592_000 // 30-day months
        }
    }
}
