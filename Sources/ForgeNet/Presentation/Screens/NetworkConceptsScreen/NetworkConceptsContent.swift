#if os(iOS) || os(visionOS)
import Foundation

enum NetworkConceptsContent {
    // MARK: - Static

    static let navTitle = "Network Concepts"
    static let intro = "ForgeNet captures every URLSession request its instrumentation sees. Tap any field to filter the stream."

    static let concepts: [Concept] = [
        .init(title: "Method",
              blurb: "The HTTP verb. Color hints at the verb family — GET (read) info-blue, POST (create) success-green, PUT/PATCH (update) amber, DELETE error-red."),
        .init(title: "Status",
              blurb: "HTTP status code, grouped into 2xx success, 3xx redirect, 4xx client error, 5xx server error. Network failures (no status) appear as red FAILED."),
        .init(title: "Caller",
              blurb: "The module + class + function that issued the request. Pass a `Caller` through your networking layer to populate this; otherwise \"Called from\" shows \"—\"."),
        .init(title: "Edge cases",
              blurb: "Redirect chains, gzip-compressed responses, image bodies, and SSE streams are flagged inline on the row and expanded into purpose-built views in detail."),
    ]

    // MARK: - Input & State

    struct Input {
        let router: ForgeNetFlowRouter
    }

    struct State {
        static let `default` = State()
    }

    // MARK: - Types

    struct Concept {
        let title: String
        let blurb: String
    }
}
#endif
