import SwiftUI

/// Pantalla 6 — Perfil / Historial: players registered on this device.
struct ProfilesView: View {
    @Environment(PlayerStatsStore.self) private var store

    @State private var pendingDelete: PlayerStats?

    var body: some View {
        List {
            if !store.stats.isEmpty {
                Section {
                    ForEach(store.sortedByName) { entry in
                        NavigationLink(value: Route.playerDetail(entry.id)) {
                            ProfileRow(stats: entry)
                        }
                        .swipeActions {
                            Button("Borrar historial", systemImage: "trash", role: .destructive) {
                                pendingDelete = entry
                            }
                        }
                    }
                } footer: {
                    Text("Jugadores registrados en este dispositivo")
                }
            }
        }
        .overlay {
            if store.stats.isEmpty {
                ContentUnavailableView(
                    "Aún no hay partidas",
                    systemImage: "person.3",
                    description: Text("Juega una ronda y aquí aparecerán las estadísticas de cada jugador.")
                )
            }
        }
        .navigationTitle("Historial")
        .confirmationDialog(
            Text("¿Borrar el historial de \(pendingDelete?.name ?? "")?"),
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Borrar historial", role: .destructive) {
                if let pendingDelete { store.delete(pendingDelete) }
            }
        }
    }
}

private struct ProfileRow: View {
    let stats: PlayerStats

    var body: some View {
        HStack(spacing: 12) {
            PlayerAvatar(name: stats.name)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: stats.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 0) {
                    Text("\(stats.gamesPlayed) partidas")
                    Text(verbatim: " · ")
                    Text("\(stats.totalPoints) pts")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            if stats.currentStreak > 1 {
                Label {
                    Text(verbatim: "\(stats.currentStreak)")
                } icon: {
                    Image(systemName: "flame.fill")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            }
        }
    }
}
