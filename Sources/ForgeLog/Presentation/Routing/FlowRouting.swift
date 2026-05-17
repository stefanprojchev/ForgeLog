#if os(iOS) || os(visionOS)
import SwiftUI

/// Minimal navigation contract shared by every `<Flow>FlowRouter` in the
/// package. The concrete router declares its `path` and `Route` enum; the
/// default implementations here supply `push` / `pop` / `popToRoot`.
///
/// This protocol intentionally lives inside the library — the conventions
/// document assumes a host-app `Presentation/Routing/FlowRouting.swift`, but
/// since ForgeLog ships its own inspector flow it defines the contract here
/// so screens written under the conventions compile without a host.
@MainActor
public protocol FlowRouting: AnyObject, Observable {
    associatedtype Route: Hashable

    // MARK: - Implementation

    var path: [Route] { get set }
}

public extension FlowRouting {
    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
#endif
