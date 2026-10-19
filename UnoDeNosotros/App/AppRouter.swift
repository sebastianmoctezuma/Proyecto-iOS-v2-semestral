import SwiftUI
import Observation

enum Route: Hashable {
    case setup
    case wordRound
    case voting
    case results
    case profiles
    case playerDetail(String)
}

@Observable
final class AppRouter {
    var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }

    /// After "Siguiente ronda": back to the word round, keeping Setup underneath.
    func restartRound() {
        path = [.setup, .wordRound]
    }
}
