import Foundation

/// Pure game rules. No UI, no persistence — easy to unit test.
nonisolated enum GameEngine {
    static let minPlayers = 3
    static let maxPlayers = 12
    static let pointsForCorrectVote = 1
    static let pointsForUndetectedImpostor = 2

    /// Two impostors only make sense with enough crew to outvote them.
    static func maxImpostors(forPlayerCount count: Int) -> Int {
        count >= 5 ? 2 : 1
    }

    static func pickImpostors<G: RandomNumberGenerator>(
        from players: [Player],
        count: Int,
        using generator: inout G
    ) -> Set<UUID> {
        let count = min(count, maxImpostors(forPlayerCount: players.count))
        return Set(players.shuffled(using: &generator).prefix(count).map(\.id))
    }

    static func pickImpostors(from players: [Player], count: Int) -> Set<UUID> {
        var generator = SystemRandomNumberGenerator()
        return pickImpostors(from: players, count: count, using: &generator)
    }

    /// Resolves the votes of a round.
    ///
    /// An impostor is *discovered* when they received at least one vote and no
    /// crew member received more votes than them (ties count as discovered).
    static func outcome(for round: Round) -> RoundOutcome {
        let players = round.players
        var counts: [UUID: Int] = [:]
        for suspect in round.votes.values {
            counts[suspect, default: 0] += 1
        }

        let crewMaxVotes = players
            .filter { !round.isImpostor($0) }
            .map { counts[$0.id, default: 0] }
            .max() ?? 0

        let impostors = players.filter(round.isImpostor)
        let caught = Set(impostors.filter { impostor in
            let votes = counts[impostor.id, default: 0]
            return votes > 0 && votes >= crewMaxVotes
        }.map(\.id))

        let correctVoters = Set(round.votes.compactMap { voter, suspect in
            !round.impostorIDs.contains(voter) && round.impostorIDs.contains(suspect) ? voter : nil
        })

        var points: [UUID: Int] = [:]
        for voter in correctVoters {
            points[voter, default: 0] += pointsForCorrectVote
        }
        for impostor in impostors where !caught.contains(impostor.id) {
            points[impostor.id, default: 0] += pointsForUndetectedImpostor
        }

        let tallies = players
            .map { player in
                VoteTally(
                    player: player,
                    votes: counts[player.id, default: 0],
                    isImpostor: round.isImpostor(player),
                    isCaught: caught.contains(player.id)
                )
            }
            .sorted { lhs, rhs in
                lhs.votes != rhs.votes ? lhs.votes > rhs.votes : lhs.isImpostor && !rhs.isImpostor
            }

        return RoundOutcome(
            impostors: impostors,
            words: round.words,
            caughtImpostorIDs: caught,
            tallies: tallies,
            points: points,
            correctVoterIDs: correctVoters
        )
    }

    /// Applies a finished round to a player's accumulated stats.
    static func updatedStats(_ stats: PlayerStats, for player: Player, in outcome: RoundOutcome, at date: Date = .now) -> PlayerStats {
        var stats = stats
        let isImpostor = outcome.impostors.contains(player)
        stats.gamesPlayed += 1
        if isImpostor {
            stats.timesImpostor += 1
            if outcome.caughtImpostorIDs.contains(player.id) { stats.timesCaught += 1 }
        }
        if outcome.correctVoterIDs.contains(player.id) { stats.correctVotes += 1 }
        stats.totalPoints += outcome.points[player.id, default: 0]
        if outcome.didWin(player) {
            stats.wins += 1
            stats.currentStreak += 1
            stats.bestStreak = max(stats.bestStreak, stats.currentStreak)
        } else {
            stats.currentStreak = 0
        }
        stats.lastPlayed = date
        return stats
    }
}
