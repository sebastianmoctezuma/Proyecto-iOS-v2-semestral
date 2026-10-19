import SwiftUI

/// Pantalla 5 — Resultados.
struct ResultsView: View {
    @Environment(GameSession.self) private var session
    @Environment(AppRouter.self) private var router

    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let outcome = session.outcome, let round = session.round {
                content(outcome: outcome, round: round)
            }
        }
        .navigationTitle("Resultados")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Inicio", systemImage: "house") { router.popToRoot() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ver perfiles", systemImage: "person.2") { router.push(.profiles) }
            }
        }
        .alert(
            Text("No se pudo iniciar la ronda"),
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("Reintentar") { nextRound() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func content(outcome: RoundOutcome, round: Round) -> some View {
        let scorers = round.players.filter { outcome.points[$0.id, default: 0] > 0 }

        return List {
            Section {
                RevealHeader(outcome: outcome)
            }

            Section("Palabras") {
                LabeledContent("Palabra secreta", value: outcome.words.word)
                LabeledContent("Hint del impostor", value: outcome.words.hint)
            }

            Section("Desglose de votación") {
                ForEach(outcome.tallies) { tally in
                    TallyRow(tally: tally)
                }
            }

            Section("Puntos de la ronda") {
                if scorers.isEmpty {
                    Text("Nadie sumó puntos esta ronda")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(scorers) { player in
                        LabeledContent(player.name) {
                            Text(verbatim: "+\(outcome.points[player.id, default: 0])")
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .disabled(session.isGenerating)
        .safeAreaInset(edge: .bottom) {
            Button {
                nextRound()
            } label: {
                Group {
                    if session.isGenerating {
                        GeneratingLabel()
                    } else {
                        Text("Siguiente ronda")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(session.isGenerating)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func nextRound() {
        Task {
            do {
                try await session.startNextRound()
                router.restartRound()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

/// Who the impostor was and who won.
private struct RevealHeader: View {
    let outcome: RoundOutcome

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: outcome.crewWins ? "person.3.fill" : "theatermasks.fill")
                .font(.system(size: 44))
                .foregroundStyle(outcome.crewWins ? Color.green : Color.red)
            Text(headline)
                .font(.title2.bold())
            Text(outcome.crewWins ? "¡Los tripulantes ganan!" : winnerText)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var names: String {
        outcome.impostors.map(\.name).formatted(.list(type: .and))
    }

    private var headline: LocalizedStringKey {
        outcome.impostors.count > 1 ? "Los impostores eran \(names)" : "El impostor era \(names)"
    }

    private var winnerText: LocalizedStringKey {
        outcome.impostors.count > 1 ? "¡Los impostores ganan!" : "¡El impostor gana!"
    }
}

/// "Americo · DESCUBIERTO · 3 votos"
private struct TallyRow: View {
    let tally: VoteTally

    var body: some View {
        HStack {
            Text(verbatim: tally.player.name)

            if tally.isImpostor {
                Text(tally.isCaught ? "Descubierto" : "Impostor")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.red.opacity(0.15), in: .capsule)
            }

            Spacer()

            Text("\(tally.votes) votos")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
