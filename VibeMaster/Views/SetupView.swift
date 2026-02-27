//
//  SetupView.swift
//  VibeMaster
//

import SwiftUI

struct SetupView: View {
    @Binding var path: [AppDestination]
    let initialTracks: [Track]?
    let onCancel: (() -> Void)?

    @State private var playerNames = ["", ""]
    @State private var timerSeconds: Double = 15
    @State private var numberOfSongs: Int = 1
    @State private var mcPlaysMode = false
    @State private var tracks: [Track] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @FocusState private var focusedPlayerIndex: Int?

    private var canStart: Bool {
        let names = playerNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return names.count >= 2 && !tracks.isEmpty
    }

    var body: some View {
        Group {
            if isLoading {
                ContentUnavailableView("Chargement…", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadError {
                ContentUnavailableView {
                    Label("Erreur", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Réessayer") {
                        loadError = nil
                        isLoading = true
                        Task {
                            let loaded = await MockPlaylistService.loadTracks()
                            await MainActor.run {
                                tracks = loaded
                                numberOfSongs = loaded.isEmpty ? 1 : loaded.count
                                isLoading = false
                                if loaded.isEmpty { loadError = "Aucune piste" }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                formContent
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if onCancel != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        onCancel?()
                    }
                }
            }
        }
        .onAppear {
            let lastNames = LastGameState.loadPlayerNames()
            if lastNames.count >= 2 {
                playerNames = lastNames
            } else if !lastNames.isEmpty {
                playerNames = lastNames + [""]
            }
            if let initial = initialTracks, !initial.isEmpty {
                tracks = initial
                numberOfSongs = initial.count
                isLoading = false
            } else {
                Task {
                    let loaded = await MockPlaylistService.loadTracks()
                    await MainActor.run {
                        tracks = loaded
                        numberOfSongs = loaded.isEmpty ? 1 : loaded.count
                        isLoading = false
                        if loaded.isEmpty { loadError = "Aucune piste" }
                    }
                }
            }
        }
    }

    @ViewBuilder private var formContent: some View {
        List {
            Section("Joueurs") {
                ForEach(Array(playerNames.enumerated()), id: \.offset) { index, name in
                    HStack {
                        TextField("Joueur \(index + 1)", text: $playerNames[index])
                            .textInputAutocapitalization(.words)
                            .focused($focusedPlayerIndex, equals: index)
                        if playerNames.count > 2 {
                            Button(role: .destructive) {
                                playerNames.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                        }
                    }
                }
                Button {
                    playerNames.append("")
                } label: {
                    Label("Ajouter un joueur", systemImage: "plus.circle")
                }
            }
            Section("Timer (secondes)") {
                HStack {
                    Text("\(Int(timerSeconds)) s")
                        .fontWeight(.medium)
                    Slider(value: $timerSeconds, in: 5...30, step: 1)
                }
            }
            if !tracks.isEmpty {
                Section("Nombre de pistes") {
                    HStack {
                        Text("\(numberOfSongs) / \(tracks.count)")
                            .fontWeight(.medium)
                        Slider(
                            value: Binding(
                                get: { Double(numberOfSongs) },
                                set: { numberOfSongs = Int($0.rounded()) }
                            ),
                            in: 1...Double(max(1, tracks.count)),
                            step: 1
                        )
                    }
                }
            }
            Section("Mode MC") {
                Toggle("Le MC joue", isOn: $mcPlaysMode)
            }
            Section {
                Button("Lancer la partie") {
                    startGame()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .disabled(!canStart)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
    }

    private func startGame() {
        let names = playerNames.compactMap { s -> String? in
            let t = s.trimmingCharacters(in: .whitespaces)
            return t.isEmpty ? nil : t
        }
        guard names.count >= 2, !tracks.isEmpty else { return }
        LastGameState.savePlayerNames(names)
        let count = min(max(1, numberOfSongs), tracks.count)
        let shuffledTracks = tracks.shuffled()
        let configTracks = Array(shuffledTracks.prefix(count))
        let seconds = Int(timerSeconds)
        let clamped = min(30, max(5, seconds))
        let config = GameConfig(tracks: configTracks, playerNames: names, timerSeconds: clamped, mcPlaysMode: mcPlaysMode)
        path.append(.game(config))
    }
}
