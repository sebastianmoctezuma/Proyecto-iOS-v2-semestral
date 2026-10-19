import SwiftUI

/// Pantalla 4 — Votación secuencial, pasando el celular.
struct VotingView: View {
    @Environment(GameSession.self) private var session
    @Environment(AppRouter.self) private var router

    @State private var voterIndex = 0
    @State private var selection: Player.ID?

    var body: some View {
        Group {
            if let round = session.round, round.players.indices.contains(voterIndex) {
                content(round: round, voter: round.players[voterIndex])
            }
        }
        .navigationTitle("Votación")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EndGameButton() }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func content(round: Round, voter: Player) -> some View {
        let candidates = round.players.filter { $0.id != voter.id }
        let isLast = voterIndex == round.players.count - 1

        return List {
            Section {
                HStack(spacing: 14) {
                    PlayerAvatar(name: voter.name, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Turno de \(voter.name)")
                            .font(.headline)
                        Text("Votante \(voterIndex + 1) de \(round.players.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("¿Quién crees que es el impostor?") {
                ForEach(candidates) { candidate in
                    Button {
                        selection = candidate.id
                    } label: {
                        HStack {
                            Text(verbatim: candidate.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selection == candidate.id {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .tint(.primary)
                    .accessibilityAddTraits(selection == candidate.id ? .isSelected : [])
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                confirm(round: round, voter: voter, candidates: candidates)
            } label: {
                Text(isLast ? "Confirmar y ver resultados" : "Confirmar voto")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selection == nil)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .id(voter.id)
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
    }

    private func confirm(round: Round, voter: Player, candidates: [Player]) {
        guard let suspect = candidates.first(where: { $0.id == selection }) else { return }
        session.castVote(voter: voter, suspect: suspect)

        if voterIndex == round.players.count - 1 {
            session.finishVoting()
            router.push(.results)
        } else {
            withAnimation(.snappy) {
                selection = nil
                voterIndex += 1
            }
        }
    }
}
