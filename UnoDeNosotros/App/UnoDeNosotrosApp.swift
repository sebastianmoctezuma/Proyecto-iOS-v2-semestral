import SwiftUI

@main
struct UnoDeNosotrosApp: App {
    @State private var session = GameSession()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(session.statsStore)
                .environment(router)
                #if DEBUG
                .task { DemoLaunch.apply(session: session, router: router) }
                #endif
        }
    }
}
