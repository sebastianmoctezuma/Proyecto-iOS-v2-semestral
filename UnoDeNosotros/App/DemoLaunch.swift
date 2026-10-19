#if DEBUG
import Foundation

/// Debug-only shortcut to open a screen with sample data, e.g. for screenshots:
/// `-demoScreen results` (setup | wordRound | impostor | voting | results | profiles).
enum DemoLaunch {
    static func apply(session: GameSession, router: AppRouter) {
        guard let screen = UserDefaults.standard.string(forKey: "demoScreen") else { return }

        let players = ["Andrea", "Edgar", "Americo", "Sebastián"].map { Player(name: $0) }
        let americo = players[2]
        let startsWithImpostor = screen == "impostor"
        var round = Round(
            setup: RoundSetup(players: startsWithImpostor ? [americo] + players.filter { $0 != americo } : players,
                              category: .animals, impostorCount: 1),
            words: SecretWords(word: "Playa", hint: "Desierto"),
            impostorIDs: [americo.id]
        )
        round.votes = [players[0].id: americo.id, players[1].id: americo.id,
                       players[3].id: americo.id, americo.id: players[3].id]

        switch screen {
        case "setup":
            router.path = [.setup]
        case "wordRound", "impostor":
            session.loadDemo(round, resolved: false)
            router.path = [.setup, .wordRound]
        case "voting":
            session.loadDemo(round, resolved: false)
            router.path = [.setup, .wordRound, .voting]
        case "results":
            session.loadDemo(round, resolved: true)
            if let outcome = session.outcome { session.statsStore.record(outcome, players: players) }
            router.path = [.setup, .wordRound, .voting, .results]
        case "profiles":
            router.path = [.profiles]
        default:
            break
        }
    }
}
#endif
