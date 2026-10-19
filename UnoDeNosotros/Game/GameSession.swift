import Foundation
import Observation

/// Holds the state of the current match and talks to the services.
@Observable
final class GameSession {
    private(set) var setup: RoundSetup?
    private(set) var round: Round?
    private(set) var outcome: RoundOutcome?
    private(set) var isGenerating = false

    @ObservationIgnored private let wordGenerator: WordGenerating
    @ObservationIgnored private let usedWords: UsedWordsStore
    @ObservationIgnored let statsStore: PlayerStatsStore
    @ObservationIgnored let lastSetup: LastSetupStore

    init(
        wordGenerator: WordGenerating = GeminiWordGenerator(),
        statsStore: PlayerStatsStore = PlayerStatsStore(),
        usedWords: UsedWordsStore = UsedWordsStore(),
        lastSetup: LastSetupStore = LastSetupStore()
    ) {
        self.wordGenerator = wordGenerator
        self.statsStore = statsStore
        self.usedWords = usedWords
        self.lastSetup = lastSetup
    }

    /// Generates the words with the AI and deals the roles.
    func startRound(with setup: RoundSetup) async throws {
        isGenerating = true
        defer { isGenerating = false }

        let language = AppConfig.contentLanguageCode
        let words = try await wordGenerator.generateWords(
            for: setup.category,
            languageName: AppConfig.contentLanguageName,
            avoiding: usedWords.words(for: setup.category, language: language)
        )
        usedWords.remember(words, for: setup.category, language: language)

        lastSetup.playerNames = setup.players.map(\.name)
        lastSetup.category = setup.category
        lastSetup.impostorCount = setup.impostorCount

        self.setup = setup
        self.outcome = nil
        self.round = Round(
            setup: setup,
            words: words,
            impostorIDs: GameEngine.pickImpostors(from: setup.players, count: setup.impostorCount)
        )
    }

    /// Same players, category and impostors — new words and roles.
    func startNextRound() async throws {
        guard let setup else { return }
        try await startRound(with: setup)
    }

    func castVote(voter: Player, suspect: Player) {
        round?.votes[voter.id] = suspect.id
    }

    /// Resolves the round and stores every player's stats.
    func finishVoting() {
        guard let round else { return }
        let outcome = GameEngine.outcome(for: round)
        statsStore.record(outcome, players: round.players)
        self.outcome = outcome
    }
}

#if DEBUG
extension GameSession {
    /// Seeds a finished/ongoing round so any screen can be opened directly (see `DemoLaunch`).
    func loadDemo(_ round: Round, resolved: Bool) {
        setup = round.setup
        self.round = round
        outcome = resolved ? GameEngine.outcome(for: round) : nil
    }
}
#endif
