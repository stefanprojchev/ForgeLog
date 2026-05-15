import Testing
import Foundation
@testable import ForgeLog

@Suite("AnyCodableValue")
struct AnyCodableValueTests {

    @Test("plainText sorts keys and joins with commas")
    func plainText() {
        let metadata: [String: AnyCodableValue] = [
            "code": .int(404),
            "type": .string("URLError"),
        ]
        let formatted = AnyCodableValue.plainText(from: metadata)
        #expect(formatted == "code=404, type=URLError")
    }

    @Test("Error converts to structured metadata")
    func errorAsMetadata() {
        struct DemoError: LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let metadata = DemoError().asMetadata

        #expect(metadata["localizedDescription"] == .string("boom"))
        #expect(metadata["type"] == .string("DemoError"))
        #expect(metadata["domain"] != nil)
        if case .int = metadata["code"] {
            // ok
        } else {
            Issue.record("code should be an int")
        }
    }

    @Test("Encodable values are flattened to metadata dictionaries")
    func encodableMetadata() {
        struct User: Encodable {
            let id: Int
            let name: String
        }
        let metadata = User(id: 1, name: "Alice").asLogMetadata
        #expect(metadata["id"] == .int(1))
        #expect(metadata["name"] == .string("Alice"))
    }

    @Test("Dictionary merging right-hand wins")
    func merging() {
        let a: [String: AnyCodableValue] = ["x": .int(1), "y": .int(2)]
        let b: [String: AnyCodableValue] = ["y": .int(99), "z": .int(3)]
        let merged = a + b
        #expect(merged["x"] == .int(1))
        #expect(merged["y"] == .int(99))
        #expect(merged["z"] == .int(3))
    }

    @Test("Round-trips through JSON")
    func codable() throws {
        let original: AnyCodableValue = .dictionary([
            "string": .string("hi"),
            "int": .int(42),
            "bool": .bool(true),
            "null": .null,
            "array": .array([.int(1), .int(2)]),
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodableValue.self, from: data)
        #expect(decoded == original)
    }
}
