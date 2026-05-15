import Testing
@testable import ForgeLog

@Suite("LogLevel")
struct LogLevelTests {

    @Test("Comparable orders levels by severity")
    func ordering() {
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
    }

    @Test("Raw values are stable")
    func rawValues() {
        #expect(LogLevel.debug.rawValue == 0)
        #expect(LogLevel.info.rawValue == 1)
        #expect(LogLevel.warning.rawValue == 2)
        #expect(LogLevel.error.rawValue == 3)
    }

    @Test("Labels are uppercase strings")
    func labels() {
        #expect(LogLevel.debug.label == "DEBUG")
        #expect(LogLevel.info.label == "INFO")
        #expect(LogLevel.warning.label == "WARNING")
        #expect(LogLevel.error.label == "ERROR")
    }

    @Test("All cases are enumerable")
    func allCases() {
        #expect(LogLevel.allCases.count == 4)
    }
}
