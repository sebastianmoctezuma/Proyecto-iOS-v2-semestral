import SwiftUI

/// Pantalla 3 — Ronda de palabra (pasar el celular).
///
/// The word stays hidden until the current player taps the card, so the next
/// player never sees the previous one's role while the phone is passed around.
struct WordRoundView: View {
    @Environment(GameSession.self) private var session
    @Environment(AppRouter.self) private var router

    @State private var index = 0
    @State private var isRevealed = false

    var body: some View {
        Group {
            if let round = session.round, round.players.indices.contains(index) {
                content(round: round, player: round.players[index])
            }
        }
        .navigationTitle("Ronda de palabra")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EndGameButton() }
        }
        .sensoryFeedback(.impact, trigger: isRevealed) { _, revealed in revealed }
        #if DEBUG
        .onAppear { isRevealed = UserDefaults.standard.bool(forKey: "demoReveal") }
        #endif
    }

    private func content(round: Round, player: Player) -> some View {
        let isLast = index == round.players.count - 1

        return VStack(spacing: 20) {
            VStack(spacing: 8) {
                ProgressView(value: Double(index + 1), total: Double(round.players.count))
                Text("Jugador \(index + 1) de \(round.players.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 4) {
                Text("Turno de")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(verbatim: player.name)
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { isRevealed = true }
            } label: {
                WordCard(round: round, player: player, isRevealed: isRevealed)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!isRevealed)

            Spacer()

            Button {
                next(isLast: isLast)
            } label: {
                Text(isLast ? "Ir a votación" : "Siguiente jugador")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isRevealed)
        }
        .padding()
        .id(player.id)
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
    }

    private func next(isLast: Bool) {
        if isLast {
            router.push(.voting)
        } else {
            withAnimation(.snappy) {
                isRevealed = false
                index += 1
            }
        }
    }
}

/// The secret word, the impostor's hint, or a cover before revealing.
private struct WordCard: View {
    let round: Round
    let player: Player
    let isRevealed: Bool

    private var isImpostor: Bool { isRevealed && round.isImpostor(player) }

    var body: some View {
        Group {
            if !isRevealed {
                cover
            } else if isImpostor {
                impostorFace
            } else {
                crewFace
            }
        }
        .multilineTextAlignment(.center)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(
            isImpostor ? AnyShapeStyle(Color.red.gradient) : AnyShapeStyle(.background.secondary),
            in: .rect(cornerRadius: 28)
        )
        .contentShape(.rect(cornerRadius: 28))
    }

    private var cover: some View {
        VStack(spacing: 10) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            Text("Toca para ver tu palabra")
                .font(.title3.weight(.semibold))
            Text("Que nadie más vea la pantalla")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var crewFace: some View {
        VStack(spacing: 8) {
            Text("Palabra secreta")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(verbatim: round.words.word)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.4)
        }
    }

    private var impostorFace: some View {
        VStack(spacing: 8) {
            Label("¡Eres el impostor!", systemImage: "theatermasks.fill")
                .font(.title2.bold())
            Text("Tu pista")
                .font(.headline)
                .opacity(0.8)
                .padding(.top, 4)
            Text(verbatim: round.words.hint)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.4)
        }
        .foregroundStyle(.white)
    }
}
