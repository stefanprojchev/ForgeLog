import Testing
import Foundation
@testable import ForgeLog

@Suite("CrashContextProvider")
struct CrashContextProviderTests {

    private func makeEntry(_ message: String) -> LogEntry {
        LogEntry(
            level: .info,
            message: message,
            className: "Test",
            functionName: "fn()",
            line: 1
        )
    }

    @Test("Keeps entries in chronological order when under capacity")
    func underCapacity() {
        let provider = CrashContextProvider(bufferSize: 3)
        provider.log(makeEntry("a"))
        provider.log(makeEntry("b"))

        let recent = provider.recentEntries()
        #expect(recent.map(\.message) == ["a", "b"])
    }

    @Test("Overwrites oldest entries when buffer is full")
    func ringBufferWrap() {
        let provider = CrashContextProvider(bufferSize: 3)
        ["a", "b", "c", "d", "e"].forEach { provider.log(makeEntry($0)) }

        let recent = provider.recentEntries()
        #expect(recent.map(\.message) == ["c", "d", "e"])
    }

    @Test("clear empties the buffer")
    func clear() {
        let provider = CrashContextProvider(bufferSize: 3)
        provider.log(makeEntry("a"))
        provider.clear()

        #expect(provider.recentEntries().isEmpty)
    }

    @Test("Respects minimumLevel filter")
    func minimumLevel() {
        let provider = CrashContextProvider(bufferSize: 10, minimumLevel: .warning)
        provider.log(LogEntry(level: .debug, message: "debug", className: "", functionName: "", line: 0))
        provider.log(LogEntry(level: .warning, message: "warn", className: "", functionName: "", line: 0))

        #expect(provider.recentEntries().map(\.message) == ["warn"])
    }
}
