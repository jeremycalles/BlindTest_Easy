//
//  SetupView.swift
//  VibeMaster
//

import SwiftUI
import VibeMasterCore

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
                ContentUnavailableView(AppStrings.Setup.loading, systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadError {
                ContentUnavailableView {
                    Label(AppStrings.Setup.errorTitle, systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button(AppStrings.Common.retry) {
                        loadError = nil
                        isLoading = true
                        Task {
                            let loaded = await MockPlaylistService.loadTracks()
                            await MainActor.run {
                                tracks = loaded
                                numberOfSongs = loaded.isEmpty ? 1 : loaded.count
                                isLoading = false
                                if loaded.isEmpty { loadError = AppStrings.Setup.noTracks }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    setupBackground
                    formContent
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(AppStrings.Setup.title)
                    .font(.headline)
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
                                if loaded.isEmpty { loadError = AppStrings.Setup.noTracks }
                    }
                }
            }
        }
    }

    private var setupBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.08, blue: 0.14),
                Color(red: 0.05, green: 0.05, blue: 0.10),
                Color(red: 0.02, green: 0.02, blue: 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var setupSliderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.7, blue: 1.0),
                Color(red: 0.5, green: 0.35, blue: 0.9)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ViewBuilder private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                playersCard
                timerCard
                if !tracks.isEmpty { songsCountCard }
                mcPlaysCard
                startGameButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 56) }
        .preferredColorScheme(.dark)
    }

    private var playersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.Setup.playersSection)
                .font(.headline)
                .foregroundStyle(.primary)

            ForEach(Array(playerNames.enumerated()), id: \.offset) { index, _ in
                HStack(spacing: 8) {
                    TextField(AppStrings.Setup.playerPlaceholder(index + 1), text: $playerNames[index])
                        .textInputAutocapitalization(.words)
                        .focused($focusedPlayerIndex, equals: index)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    if playerNames.count > 2 {
                        Button(role: .destructive) {
                            playerNames.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.red.opacity(0.9))
                        }
                    }
                }
            }

            Button {
                playerNames.append("")
            } label: {
                Text(AppStrings.Setup.addPlayerButton)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppStrings.Setup.timerSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(AppStrings.Setup.timerSeconds(Int(timerSeconds)))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            Slider(value: $timerSeconds, in: 5...30, step: 1)
                .tint(setupSliderGradient)
            HStack {
                Text("5s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("30s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private var songsCountCard: some View {
        let maxSongs = Double(max(1, tracks.count))
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppStrings.Setup.tracksCountSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(numberOfSongs) / \(Int(maxSongs))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(
                    get: { Double(numberOfSongs) },
                    set: { numberOfSongs = Int($0.rounded()) }
                ),
                in: 1...maxSongs,
                step: 1
            )
            .tint(setupSliderGradient)
            HStack {
                Text("1")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(maxSongs))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private var mcPlaysCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppStrings.Setup.mcPlaysToggle)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(AppStrings.Setup.mcModeSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Toggle("", isOn: $mcPlaysMode)
                    .labelsHidden()
                    .tint(Color(red: 0.55, green: 0.35, blue: 0.95))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private var startGameButton: some View {
        Button(action: startGame) {
            Text(AppStrings.Setup.startGame)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .glassEffect(.regular.interactive(), in: .capsule)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .opacity(canStart ? 1 : 0.5)
        .disabled(!canStart)
        .padding(.top, 8)
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

#Preview("SetupView") {
    NavigationStack {
        SetupView(path: .constant([]), initialTracks: nil, onCancel: nil)
    }
}
