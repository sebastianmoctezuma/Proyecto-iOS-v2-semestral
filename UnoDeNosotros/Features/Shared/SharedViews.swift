import SwiftUI

/// Toolbar button to leave a round in progress, with confirmation.
struct EndGameButton: View {
    @Environment(AppRouter.self) private var router
    @State private var isConfirming = false

    var body: some View {
        Button("Terminar", systemImage: "xmark") {
            isConfirming = true
        }
        .confirmationDialog("¿Terminar la partida?", isPresented: $isConfirming, titleVisibility: .visible) {
            Button("Terminar partida", role: .destructive) { router.popToRoot() }
        } message: {
            Text("La ronda actual no se guardará.")
        }
    }
}

/// Blocks interaction while Gemini generates the secret words.
struct GeneratingLabel: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Generando palabra secreta…")
        }
    }
}

/// Circle with the player's initial.
struct PlayerAvatar: View {
    let name: String
    var size: CGFloat = 40

    var body: some View {
        Text(verbatim: String(name.prefix(1)).uppercased())
            .font(.system(size: size * 0.45, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.accentColor.gradient, in: .circle)
            .accessibilityHidden(true)
    }
}
