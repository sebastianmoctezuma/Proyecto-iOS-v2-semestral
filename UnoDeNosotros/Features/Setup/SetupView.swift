import SwiftUI

/// Pantalla 2 — Configuración de partida.
struct SetupView: View {
    @Environment(GameSession.self) private var session
    @Environment(PlayerStatsStore.self) private var statsStore
    @Environment(AppRouter.self) private var router

    @State private var model: SetupViewModel?
    @State private var errorMessage: String?
    @FocusState private var focusedField: UUID?

    var body: some View {
        Group {
            if let model {
                form(model)
            } else {
                Color.clear
            }
        }
        .navigationTitle("Configura tu partida")
        .onAppear {
            if model == nil { model = SetupViewModel(lastSetup: session.lastSetup) }
        }
        .alert(
            Text("No se pudo iniciar la ronda"),
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("Reintentar") { startRound() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func form(_ model: SetupViewModel) -> some View {
        @Bindable var model = model
        let savedNames = model.availableSavedNames(from: statsStore.sortedByName)

        return Form {
            Section {
                Stepper(
                    value: Binding(get: { model.playerCount }, set: { model.setPlayerCount($0) }),
                    in: GameEngine.minPlayers...GameEngine.maxPlayers
                ) {
                    LabeledContent("Número de jugadores", value: model.playerCount.formatted())
                }

                ForEach(Array(model.entries.enumerated()), id: \.element.id) { index, entry in
                    nameRow(model, entry: entry, index: index, savedNames: savedNames)
                }
                .onDelete { offsets in
                    let removed = offsets.map { model.entries[$0] }
                    withAnimation { removed.forEach(model.removeRow) }
                }
                .deleteDisabled(model.playerCount <= GameEngine.minPlayers)
            } header: {
                Text("Jugadores")
            } footer: {
                if let message = model.validationMessage, model.trimmedNames.contains(where: { !$0.isEmpty }) {
                    Text(message).foregroundStyle(.red)
                } else {
                    Text("Desliza un nombre a la izquierda para quitarlo.")
                }
            }

            Section("Categoría") {
                Picker("Categoría", selection: $model.category) {
                    ForEach(WordCategory.allCases) { category in
                        Label {
                            Text(category.title)
                        } icon: {
                            Image(systemName: category.symbol)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section {
                Picker("Impostores", selection: $model.impostorCount) {
                    Label("1", systemImage: "person.fill").tag(1)
                    Label("2", systemImage: "person.2.fill").tag(2)
                }
                .pickerStyle(.segmented)
                .disabled(model.maxImpostors < 2)
            } header: {
                Text("Número de impostores")
            } footer: {
                if model.maxImpostors < 2 {
                    Text("Se necesitan al menos 5 jugadores para jugar con 2 impostores.")
                }
            }
        }
        .disabled(session.isGenerating)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button {
                startRound()
            } label: {
                Group {
                    if session.isGenerating {
                        GeneratingLabel()
                    } else {
                        Text("Iniciar ronda")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!model.canStart || session.isGenerating)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func nameRow(_ model: SetupViewModel, entry: SetupViewModel.NameEntry, index: Int, savedNames: [String]) -> some View {
        HStack {
            TextField(
                "Nombre \(index + 1)",
                text: Binding(
                    get: { model.entries.first(where: { $0.id == entry.id })?.name ?? "" },
                    set: { model.fill(entry, with: $0) }
                )
            )
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(index == model.entries.count - 1 ? .done : .next)
            .focused($focusedField, equals: entry.id)
            .onSubmit {
                let next = index + 1
                focusedField = model.entries.indices.contains(next) ? model.entries[next].id : nil
            }

            if !savedNames.isEmpty {
                Menu {
                    Section("Jugadores guardados") {
                        ForEach(savedNames, id: \.self) { saved in
                            Button(saved) { model.fill(entry, with: saved) }
                        }
                    }
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .imageScale(.large)
                }
                .accessibilityLabel(Text("Elegir jugador guardado"))
            }
        }
    }

    // MARK: - Actions

    private func startRound() {
        guard let model, model.canStart else { return }
        focusedField = nil
        let setup = model.makeSetup()
        Task {
            do {
                try await session.startRound(with: setup)
                router.push(.wordRound)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    let session = GameSession()
    NavigationStack {
        SetupView()
    }
    .environment(session)
    .environment(session.statsStore)
    .environment(AppRouter())
}
