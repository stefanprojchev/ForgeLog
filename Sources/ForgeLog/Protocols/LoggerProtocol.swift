import Foundation

/// The main logger interface.
///
/// Conforming types implement `log(level:_:metadata:processes:file:function:line:)`
/// and the provider management methods. All per-level convenience methods
/// (`debug`, `info`, `warning`, `error`) and metadata-converting overloads
/// are provided via extensions.
public protocol LoggerProtocol: Sendable {
    /// The single logging entry point. All convenience methods delegate here.
    func log(
        level: LogLevel,
        _ message: String,
        metadata: [String: AnyCodableValue]?,
        processes: [String],
        file: String,
        function: String,
        line: Int
    )

    /// Registers a new provider at runtime.
    func addProvider(_ provider: LogProviderProtocol)

    /// Removes the first provider matching the given name.
    /// - Returns: `true` if a provider was removed, `false` if no match was found.
    @discardableResult
    func removeProvider(named name: String) -> Bool

    /// Removes all registered providers.
    func removeAllProviders()

    /// Returns the names of all currently registered providers.
    var providerNames: [String] { get }
}

// MARK: - Per-Level Convenience (Dictionary Metadata)

public extension LoggerProtocol {
    func debug(
        _ message: String,
        metadata: [String: AnyCodableValue]? = nil,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message, metadata: metadata, processes: processes, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        metadata: [String: AnyCodableValue]? = nil,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message, metadata: metadata, processes: processes, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        metadata: [String: AnyCodableValue]? = nil,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message, metadata: metadata, processes: processes, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        metadata: [String: AnyCodableValue]? = nil,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message, metadata: metadata, processes: processes, file: file, function: function, line: line)
    }
}

// MARK: - Single Error Metadata Convenience

public extension LoggerProtocol {
    func debug(
        _ message: String,
        metadata error: Error,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message, metadata: error.asMetadata, processes: processes, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        metadata error: Error,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message, metadata: error.asMetadata, processes: processes, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        metadata error: Error,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message, metadata: error.asMetadata, processes: processes, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        metadata error: Error,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message, metadata: error.asMetadata, processes: processes, file: file, function: function, line: line)
    }
}

// MARK: - Error Array Metadata Convenience

public extension LoggerProtocol {
    func debug(
        _ message: String,
        metadata errors: [Error],
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message, metadata: AnyCodableValue.from(errors), processes: processes, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        metadata errors: [Error],
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message, metadata: AnyCodableValue.from(errors), processes: processes, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        metadata errors: [Error],
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message, metadata: AnyCodableValue.from(errors), processes: processes, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        metadata errors: [Error],
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message, metadata: AnyCodableValue.from(errors), processes: processes, file: file, function: function, line: line)
    }
}

// MARK: - Encodable Metadata Convenience

public extension LoggerProtocol {
    func debug<T: Encodable>(
        _ message: String,
        metadata value: T,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message, metadata: AnyCodableValue.from(value), processes: processes, file: file, function: function, line: line)
    }

    func info<T: Encodable>(
        _ message: String,
        metadata value: T,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message, metadata: AnyCodableValue.from(value), processes: processes, file: file, function: function, line: line)
    }

    func warning<T: Encodable>(
        _ message: String,
        metadata value: T,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message, metadata: AnyCodableValue.from(value), processes: processes, file: file, function: function, line: line)
    }

    func error<T: Encodable>(
        _ message: String,
        metadata value: T,
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message, metadata: AnyCodableValue.from(value), processes: processes, file: file, function: function, line: line)
    }
}

// MARK: - Encodable Array Metadata Convenience

public extension LoggerProtocol {
    func debug<T: Encodable>(
        _ message: String,
        metadata values: [T],
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message, metadata: AnyCodableValue.from(values), processes: processes, file: file, function: function, line: line)
    }

    func info<T: Encodable>(
        _ message: String,
        metadata values: [T],
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message, metadata: AnyCodableValue.from(values), processes: processes, file: file, function: function, line: line)
    }

    func warning<T: Encodable>(
        _ message: String,
        metadata values: [T],
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message, metadata: AnyCodableValue.from(values), processes: processes, file: file, function: function, line: line)
    }

    func error<T: Encodable>(
        _ message: String,
        metadata values: [T],
        processes: [String] = [],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message, metadata: AnyCodableValue.from(values), processes: processes, file: file, function: function, line: line)
    }
}
