import Testing
import Foundation
@testable import ForgeLog

@Suite("LogEntry")
struct LogEntryTests {

    @Test("Formatted message includes emoji, plain text does not")
    func formatting() {
        let entry = LogEntry(
            timestamp: Date(timeIntervalSince1970: 0),
            level: .warning,
            message: "disk almost full",
            className: "DiskMonitor",
            functionName: "check()",
            line: 42
        )

        #expect(entry.formattedMessage.contains("⚠️"))
        #expect(entry.formattedMessage.contains("WARNING"))
        #expect(!entry.plainTextMessage.contains("⚠️"))
        #expect(entry.plainTextMessage.contains("WARNING"))
        #expect(entry.formattedMessage.contains("DiskMonitor.check():42"))
    }

    @Test("Round-trips through JSON")
    func codable() throws {
        let original = LogEntry(
            level: .info,
            message: "hello",
            className: "Greeter",
            functionName: "greet()",
            line: 7,
            processes: ["Onboarding"],
            module: "ForgeLogTests",
            metadata: ["userId": .int(42), "country": .string("MK")]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LogEntry.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.level == original.level)
        #expect(decoded.message == original.message)
        #expect(decoded.processes == original.processes)
        #expect(decoded.module == original.module)
        #expect(decoded.metadata?["userId"] == .int(42))
    }

    @Test("hasMetadata reflects dictionary state")
    func hasMetadata() {
        let withMetadata = LogEntry(
            level: .debug, message: "", className: "", functionName: "", line: 0,
            metadata: ["a": .int(1)]
        )
        let empty = LogEntry(
            level: .debug, message: "", className: "", functionName: "", line: 0,
            metadata: [:]
        )
        let none = LogEntry(
            level: .debug, message: "", className: "", functionName: "", line: 0
        )

        #expect(withMetadata.hasMetadata)
        #expect(!empty.hasMetadata)
        #expect(!none.hasMetadata)
    }
}
