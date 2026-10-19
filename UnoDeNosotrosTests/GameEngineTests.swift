import Foundation
import Testing
@testable import UnoDeNosotros

struct GameEngineTests {
    let andrea = Player(name: "Andrea")
    let edgar = Player(name: "Edgar")
    let americo = Player(name: "Americo")
    let sebastian = Player(name: "Sebastián")
    let words = SecretWords(word: "Playa", hint: "Desierto")

    private func round(impostors: [Player], votes: [(Player, Player)]) -> Round {
        var round = Round(
            setup: RoundSetup(players: [andrea, edgar, americo, sebastian], category: .animals, impostorCount: impostors.count),
            words: words,
            impostorIDs: Set(impostors.map(\.id))
        )
        for (voter, suspect) in votes { round.votes[voter.id] = suspect.id }
        return round
    }

    @Test func impostorWithMostVotesIsCaught() {
        let outcome = GameEngine.outcome(for: round(impostors: [americo], votes: [
            (andrea, americo), (edgar, americo), (sebastian, americo), (americo, sebastian)
        ]))

        #expect(outcome.crewWins)
        #expect(outcome.caughtImpostorIDs == [americo.id])
        #expect(outcome.tallies.first?.player == americo)
        #expect(outcome.tallies.first?.votes == 3)
        #expect(outcome.points[andrea.id] == GameEngine.pointsForCorrectVote)
        #expect(outcome.points[americo.id] == nil)
    }

    @Test func impostorThatGoesUnnoticedScores() {
        let outcome = GameEngine.outcome(for: round(impostors: [americo], votes: [
            (andrea, edgar), (edgar, sebastian), (sebastian, edgar), (americo, edgar)
        ]))

        #expect(!outcome.crewWins)
        #expect(outcome.caughtImpostorIDs.isEmpty)
        #expect(outcome.points[americo.id] == GameEngine.pointsForUndetectedImpostor)
        #expect(outcome.correctVoterIDs.isEmpty)
    }

    @Test func tieWithCrewCountsAsCaught() {
        let outcome = GameEngine.outcome(for: round(impostors: [americo], votes: [
            (andrea, americo), (edgar, americo), (sebastian, edgar), (americo, edgar)
        ]))
        #expect(outcome.crewWins)
    }

    @Test func crewNeedsToCatchBothImpostors() {
        let outcome = GameEngine.outcome(for: round(impostors: [americo, edgar], votes: [
            (andrea, americo), (sebastian, americo), (americo, andrea), (edgar, sebastian)
        ]))
        #expect(outcome.caughtImpostorIDs == [americo.id])
        #expect(!outcome.crewWins)
        #expect(outcome.didWin(edgar))
        #expect(!outcome.didWin(andrea))
    }

    @Test func statsAccumulateAndStreakResets() {
        let caught = GameEngine.outcome(for: round(impostors: [americo], votes: [
            (andrea, americo), (edgar, americo), (sebastian, americo), (americo, sebastian)
        ]))
        var andreaStats = GameEngine.updatedStats(PlayerStats(name: "Andrea"), for: andrea, in: caught)
        andreaStats = GameEngine.updatedStats(andreaStats, for: andrea, in: caught)
        #expect(andreaStats.gamesPlayed == 2)
        #expect(andreaStats.correctVotes == 2)
        #expect(andreaStats.currentStreak == 2)
        #expect(andreaStats.bestStreak == 2)

        let americoStats = GameEngine.updatedStats(PlayerStats(name: "Americo", currentStreak: 3), for: americo, in: caught)
        #expect(americoStats.timesImpostor == 1)
        #expect(americoStats.timesCaught == 1)
        #expect(americoStats.currentStreak == 0)
    }

    @Test func pickImpostorsRespectsPlayerCount() {
        let three = [andrea, edgar, americo]
        #expect(GameEngine.pickImpostors(from: three, count: 2).count == 1)
        let six = three + [sebastian, Player(name: "Jaimito"), Player(name: "Jorge")]
        #expect(GameEngine.pickImpostors(from: six, count: 2).count == 2)
    }

    @Test func playerKeyIgnoresCaseAndAccents() {
        #expect(PlayerStats.key(for: " Sebastián ") == PlayerStats.key(for: "sebastian"))
    }

    @Test func rejectsRepeatedOrIdenticalWords() {
        #expect(!GeminiWordGenerator.isValid(SecretWords(word: "Playa", hint: "playa"), avoiding: []))
        #expect(!GeminiWordGenerator.isValid(SecretWords(word: "Playa", hint: "Desierto"), avoiding: ["playa"]))
        #expect(GeminiWordGenerator.isValid(SecretWords(word: "Playa", hint: "Desierto"), avoiding: ["selva"]))
    }
}
