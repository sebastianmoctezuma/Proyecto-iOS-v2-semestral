import Foundation

/// Accumulated history of a player stored on the device.
nonisolated struct PlayerStats: Identifiable, Codable, Equatable, Sendable {
    var name: String
    var gamesPlayed = 0
    var timesImpostor = 0
    var timesCaught = 0
    var correctVotes = 0
    var currentStreak = 0
    var bestStreak = 0
    var totalPoints = 0
    var wins = 0
    var lastPlayed: Date?

    var id: String { PlayerStats.key(for: name) }

    /// Players are identified by their name, case and accent insensitive.
    static func key(for name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
