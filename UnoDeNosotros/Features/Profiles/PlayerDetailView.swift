import SwiftUI

/// Accumulated statistics of a single player.
struct PlayerDetailView: View {
    let playerID: String

    @Environment(PlayerStatsStore.self) private var store

    private var stats: PlayerStats? {
        store.stats.first { $0.id == playerID }
    }

    var body: some View {
        if let stats {
            List {
                Section {
                    PlayerAvatar(name: stats.name, size: 80)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }

                Section("Partidas") {
                    StatRow(title: "Partidas jugadas", symbol: "gamecontroller.fill", value: stats.gamesPlayed)
                    StatRow(title: "Veces impostor", symbol: "theatermasks.fill", value: stats.timesImpostor)
                    StatRow(title: "Veces descubierto", symbol: "magnifyingglass", value: stats.timesCaught)
                    StatRow(title: "Votos acertados", symbol: "checkmark.seal.fill", value: stats.correctVotes)
                }

                Section("Rachas") {
                    StatRow(title: "Racha actual", symbol: "flame.fill", value: stats.currentStreak)
                    StatRow(title: "Mejor racha", symbol: "trophy.fill", value: stats.bestStreak)
                }

                Section {
                    StatRow(title: "Puntos totales", symbol: "star.fill", value: stats.totalPoints)
                        .fontWeight(.semibold)
                } footer: {
                    if let lastPlayed = stats.lastPlayed {
                        Text("Última partida: \(lastPlayed.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
            }
            .navigationTitle(stats.name)
        }
    }
}

private struct StatRow: View {
    let title: LocalizedStringKey
    let symbol: String
    let value: Int

    var body: some View {
        LabeledContent {
            Text(value, format: .number)
                .monospacedDigit()
        } label: {
            Label(title, systemImage: symbol)
        }
    }
}
