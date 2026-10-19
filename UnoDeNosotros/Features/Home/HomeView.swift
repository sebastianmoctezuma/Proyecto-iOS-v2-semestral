import SwiftUI

/// Pantalla 1 — Inicio.
struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "theatermasks.fill")
                .font(.system(size: 96))
                .foregroundStyle(.tint)
                .symbolEffect(.bounce, value: appeared)
                .accessibilityHidden(true)

            Text(verbatim: "Uno de Nosotros")
                .font(.largeTitle.bold())
                .padding(.top, 20)
                .accessibilityAddTraits(.isHeader)

            Text("Todos tienen la misma palabra… excepto el impostor.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 6)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    router.push(.setup)
                } label: {
                    Label("Comenzar a jugar", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    router.push(.profiles)
                } label: {
                    Label("Ver historial", systemImage: "chart.bar.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .onAppear { appeared = true }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppRouter())
}
