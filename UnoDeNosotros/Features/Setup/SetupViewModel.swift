import Foundation
import Observation

/// State of the "Configura tu partida" form.
@Observable
final class SetupViewModel {
    struct NameEntry: Identifiable, Equatable {
        let id = UUID()
        var name: String
    }

    var entries: [NameEntry]
    var category: WordCategory
    var impostorCount: Int
    var playerCountText: String

    init(lastSetup: LastSetupStore) {
        let saved = lastSetup.playerNames
        let names = saved.count >= GameEngine.minPlayers ? saved : Array(repeating: "", count: GameEngine.minPlayers)
        entries = names.map { NameEntry(name: $0) }
        category = lastSetup.category
        impostorCount = lastSetup.impostorCount
        playerCountText = String(names.count)
        clampImpostors()
    }

    var playerCount: Int { entries.count }

    var maxImpostors: Int { GameEngine.maxImpostors(forPlayerCount: playerCount) }

    var trimmedNames: [String] {
        entries.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    var hasDuplicateNames: Bool {
        let keys = trimmedNames.filter { !$0.isEmpty }.map(PlayerStats.key(for:))
        return Set(keys).count != keys.count
    }

    var validationMessage: LocalizedStringResource? {
        if trimmedNames.contains(where: \.isEmpty) { return "Escribe el nombre de todos los jugadores." }
        if hasDuplicateNames { return "Los nombres no se pueden repetir." }
        return nil
    }

    var canStart: Bool { validationMessage == nil }

    // MARK: - Player count

    func setPlayerCount(_ count: Int) {
        let count = min(max(count, GameEngine.minPlayers), GameEngine.maxPlayers)
        if count > entries.count {
            entries.append(contentsOf: (entries.count..<count).map { _ in NameEntry(name: "") })
        } else if count < entries.count {
            entries.removeLast(entries.count - count)
        }
        playerCountText = String(count)
        clampImpostors()
    }

    func incrementPlayers() { setPlayerCount(playerCount + 1) }
    func decrementPlayers() { setPlayerCount(playerCount - 1) }

    func commitPlayerCountText() {
        setPlayerCount(Int(playerCountText) ?? playerCount)
    }

    // MARK: - Rows

    func insertRow(after entry: NameEntry) {
        guard playerCount < GameEngine.maxPlayers, let index = entries.firstIndex(of: entry) else { return }
        entries.insert(NameEntry(name: ""), at: index + 1)
        playerCountText = String(playerCount)
        clampImpostors()
    }

    func removeRow(_ entry: NameEntry) {
        guard playerCount > GameEngine.minPlayers else { return }
        entries.removeAll { $0.id == entry.id }
        playerCountText = String(playerCount)
        clampImpostors()
    }

    func fill(_ entry: NameEntry, with name: String) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index].name = name
    }

    /// Saved players not already typed in another row.
    func availableSavedNames(from stats: [PlayerStats]) -> [String] {
        let used = Set(trimmedNames.map(PlayerStats.key(for:)))
        return stats.map(\.name).filter { !used.contains(PlayerStats.key(for: $0)) }
    }

    private func clampImpostors() {
        impostorCount = min(max(impostorCount, 1), maxImpostors)
    }

    func makeSetup() -> RoundSetup {
        RoundSetup(
            players: trimmedNames.map { Player(name: $0) },
            category: category,
            impostorCount: impostorCount
        )
    }
}
