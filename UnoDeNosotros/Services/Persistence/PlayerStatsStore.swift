import Foundation
import Observation

/// Persists every player's history in `UserDefaults` (JSON encoded).
@Observable
final class PlayerStatsStore {
    private(set) var stats: [PlayerStats] = []

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "playerStats.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    var sortedByName: [PlayerStats] {
        stats.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func stats(for name: String) -> PlayerStats? {
        let key = PlayerStats.key(for: name)
        return stats.first { $0.id == key }
    }

    /// Records a finished round for every player that took part.
    func record(_ outcome: RoundOutcome, players: [Player]) {
        for player in players {
            let current = stats(for: player.name) ?? PlayerStats(name: player.name)
            var updated = GameEngine.updatedStats(current, for: player, in: outcome)
            updated.name = player.name
            upsert(updated)
        }
        save()
    }

    func delete(_ entry: PlayerStats) {
        stats.removeAll { $0.id == entry.id }
        save()
    }

    private func upsert(_ entry: PlayerStats) {
        if let index = stats.firstIndex(where: { $0.id == entry.id }) {
            stats[index] = entry
        } else {
            stats.append(entry)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PlayerStats].self, from: data) else { return }
        stats = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
