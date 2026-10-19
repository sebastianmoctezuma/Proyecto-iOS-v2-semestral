import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .setup: SetupView()
        case .wordRound: WordRoundView()
        case .voting: VotingView()
        case .results: ResultsView()
        case .profiles: ProfilesView()
        case .playerDetail(let id): PlayerDetailView(playerID: id)
        }
    }
}
