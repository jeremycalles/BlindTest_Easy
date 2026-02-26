//
//  GameView.swift
//  VibeMaster
//

import SwiftUI

struct GameView: View {
    let config: GameConfig
    @Binding var path: [AppDestination]
    @StateObject private var engine: GameEngine
    @State private var showStopGameConfirmation = false

    init(config: GameConfig, path: Binding<[AppDestination]>) {
        self.config = config
        _path = path
        _engine = StateObject(wrappedValue: GameEngine(config))
    }

    var body: some View {
        ZStack {
            backgroundLayer
            VStack(spacing: 12) {
                if let track = engine.currentTrack {
                    trackCard(track)
                }
                trackHeader
                playerGrid
                timerStrip
                controlBar
            }
            .padding()
        }
        .safeAreaInset(edge: .top, spacing: 8) { Color.clear.frame(height: 8) }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: max(14, 0))
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    showStopGameConfirmation = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
        .confirmationDialog("Arrêter la partie ?", isPresented: $showStopGameConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Arrêter la partie", role: .destructive) {
                path = [.dashboard]
            }
        } message: {
            Text("La partie en cours sera abandonnée.")
        }
        .onAppear {
            engine.startRound()
        }
        .onDisappear {
            engine.togglePlayPause()
        }
    }

    private var backgroundLayer: some View {
        Group {
            if let track = engine.currentTrack, let url = URL(string: track.album.cover_medium) {
                AsyncImage(url: url) { image in image.resizable() }
                    placeholder: { Color.indigo.opacity(0.6) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 80)
                    .ignoresSafeArea()
            } else {
                Color.indigo.opacity(0.6)
                    .ignoresSafeArea()
            }
        }
        .overlay(.ultraThinMaterial)
    }

    private var trackHeader: some View {
        Text("PISTE \(engine.currentTrackIndex + 1) / \(config.tracks.count)")
            .font(.caption)
            .fontWeight(.medium)
            .tracking(1.5)
            .foregroundStyle(.secondary)
    }

    private func trackCard(_ track: Track) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: track.album.cover_medium)) { image in image.resizable() }
                placeholder: { Color.gray.opacity(0.3) }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(track.artist.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if config.mcPlaysMode && !engine.isRevealed {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThickMaterial)
            }
        }
    }

    private var playerGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(config.playerNames, id: \.self) { name in
                PlayerTile(
                    name: name,
                    score: engine.scores[name] ?? 0,
                    color: playerColor(for: name),
                    onTap: { engine.addPoint(playerName: name); HapticManager.light() },
                    onDoubleTap: { engine.addPoints(2, playerName: name); HapticManager.medium() },
                    onLongPress: {
                        if (engine.scores[name] ?? 0) > 0 {
                            engine.addPoints(-1, playerName: name)
                            HapticManager.light()
                        }
                    }
                )
            }
        }
        .frame(minHeight: 164 * 2 + 12)
    }

    private var timerStrip: some View {
        HStack {
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
            if engine.roundEnded {
                Text("TEMPS ÉCOULÉ")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .tracking(1.5)
                    .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.4))
            } else {
                let m = engine.timeRemaining / 60
                let s = engine.timeRemaining % 60
                Text(String(format: "%d:%02d", m, s))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    private var controlBar: some View {
        ZStack {
            Button {
                engine.togglePlayPause()
                HapticManager.medium()
            } label: {
                Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.2))
            }
            .frame(maxWidth: .infinity)

            if engine.roundEnded {
                if engine.currentTrackIndex + 1 >= config.tracks.count {
                    Button("Podium") {
                        let result = engine.buildPodiumResult()
                        path.append(.podium(result))
                    }
                    .fontWeight(.semibold)
                    .frame(width: 90, height: 44)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Button("Suivant") {
                        engine.nextTrack()
                        HapticManager.medium()
                    }
                    .fontWeight(.semibold)
                    .frame(width: 90, height: 44)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }

    private func playerColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(red: 1, green: 0.4, blue: 0.4),
            Color(red: 0.25, green: 0.8, blue: 0.8),
            Color(red: 0.53, green: 0.81, blue: 0.98),
            Color(red: 0.7, green: 0.65, blue: 0.9),
            Color(red: 1, green: 0.84, blue: 0),
            Color(red: 0.6, green: 0.98, blue: 0.6)
        ]
        let idx = config.playerNames.firstIndex(of: name) ?? 0
        return colors[idx % colors.count]
    }
}

struct PlayerTile: View {
    let name: String
    let score: Int
    let color: Color
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Circle()
                        .stroke(color, lineWidth: 2.5)
                        .frame(width: 50, height: 50)
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(color)
                }
                Text(name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(color)
                Text("\(score)")
                    .font(.system(size: 26, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(color)
                Text("pts")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(color.opacity(0.85))
            }
            .frame(minHeight: 140)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Diminuer le score", role: .none) {
                onLongPress()
            }
            .disabled(score <= 0)
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { _ in onDoubleTap() }
        )
    }
}
