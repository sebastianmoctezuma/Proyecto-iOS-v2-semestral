import Foundation

/// What the group configured on the Setup screen.
nonisolated struct RoundSetup: Equatable, Sendable {
    var players: [Player]
    var category: WordCategory
    var impostorCount: Int
}

/// A round in progress.
nonisolated struct Round: Equatable, Sendable {
    let setup: RoundSetup
    let words: SecretWords
    let impostorIDs: Set<UUID>
    /// voter → suspect
    var votes: [UUID: UUID] = [:]

    var players: [Player] { setup.players }

    func isImpostor(_ player: Player) -> Bool {
        impostorIDs.contains(player.id)
    }
}

/// Vote count for a single player on the Results screen.
nonisolated struct VoteTally: Identifiable, Equatable, Sendable {
    let player: Player
    let votes: Int
    let isImpostor: Bool
    let isCaught: Bool

    var id: UUID { player.id }
}

/// Everything the Results screen shows, computed by `GameEngine`.
nonisolated struct RoundOutcome: Equatable, Sendable {
    let impostors: [Player]
    let words: SecretWords
    let caughtImpostorIDs: Set<UUID>
    let tallies: [VoteTally]
    /// Points earned this round, by player id (only players that scored).
    let points: [UUID: Int]
    /// Crew members that voted for an impostor.
    let correctVoterIDs: Set<UUID>

    /// The crew wins only when every impostor was discovered.
    var crewWins: Bool { caughtImpostorIDs.count == impostors.count }

    func didWin(_ player: Player) -> Bool {
        if impostors.contains(player) {
            return !caughtImpostorIDs.contains(player.id)
        }
        return crewWins
    }
}
