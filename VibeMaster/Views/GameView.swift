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
    @State private var timerBounceScale: CGFloat = 1.0

    init(config: GameConfig, path: Binding<[AppDestination]>) {
        self.config = config
        _path = path
        _engine = StateObject(wrappedValue: GameEngine(config))
    }

    // Manual position for track header — change trackHeaderTop / trackHeaderLeading to move it.
    // For center: use .frame(maxWidth: .infinity) on trackHeader and ZStack(alignment: .top).
    private let trackHeaderTop: CGFloat = -90
    private let trackHeaderLeading: CGFloat = 70
    /// Fixed height for the track card so its size stays the same in all states.
    private let trackCardHeight: CGFloat = 56
    /// Y position of the track card (offset from top of game content). Change to move the card vertically.
    private let trackCardTop: CGFloat = -50
    /// Minimum vertical gap between the track card and the player grid. Keeps the layout balanced.
    private let trackCardToGridGap: CGFloat = 12

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundLayer
            GeometryReader { geo in
                let topReserved = max(0, trackCardTop + trackCardHeight) + trackCardToGridGap
                let bottomReserved: CGFloat = 110
                let gridHeight = max(60, geo.size.height - topReserved - bottomReserved - 12 * 2)
                VStack(alignment: .leading, spacing: 12) {
                    Color.clear.frame(height: topReserved)
                    playerGrid(availableHeight: gridHeight)
                        .frame(height: gridHeight)
                    timerStrip
                    controlBar
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom)
            trackHeader
                .padding(.top, trackHeaderTop)
                .padding(.leading, trackHeaderLeading)
            if let track = engine.currentTrack {
                trackCard(track)
                    .padding(.top, trackCardTop)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: 0) }
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
                    placeholder: { Color.indigo.opacity(0.8) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 80)
                    .ignoresSafeArea()
            } else {
                Color.indigo.opacity(0.8)
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
        .frame(height: trackCardHeight)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if config.mcPlaysMode && !engine.isRevealed {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThickMaterial)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func playerGrid(availableHeight: CGFloat) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        let rowCount = (config.playerNames.count + 1) / 2
        let spacing: CGFloat = 12
        let rowHeight = rowCount > 0 ? (availableHeight - spacing * CGFloat(rowCount - 1)) / CGFloat(rowCount) : 80
        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(config.playerNames, id: \.self) { name in
                PlayerTile(
                    name: name,
                    score: engine.scores[name] ?? 0,
                    color: playerColor(for: name),
                    rowHeight: rowHeight,
                    onTap: { engine.addPoint(playerName: name); HapticManager.medium() },
                    onDoubleTap: { engine.addPoint(playerName: name); HapticManager.medium() },
                    onLongPress: {
                        if (engine.scores[name] ?? 0) > 0 {
                            engine.addPoints(-1, playerName: name)
                            HapticManager.medium()
                        }
                    }
                )
            }
        }
    }

    private var timerStripBaseScale: CGFloat {
        if engine.roundEnded { return 1.2 }
        let remaining = CGFloat(engine.timeRemaining)
        let factor = max(0, 3 - remaining) / 3 * 0.4
        return 1.0 + factor
    }

    private var timerStrip: some View {
        HStack {
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
            timerStripContent
            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
        }
        .scaleEffect(timerStripBaseScale * timerBounceScale)
        .animation(.easeInOut(duration: 0.3), value: engine.timeRemaining)
        .padding(.vertical, 4)
        .onChange(of: engine.roundEnded) { _, ended in
            if ended {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { timerBounceScale = 1.35 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { timerBounceScale = 1.0 }
                }
            } else {
                timerBounceScale = 1.0
            }
        }
    }

    @ViewBuilder
    private var timerStripContent: some View {
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
    var rowHeight: CGFloat = 140
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onLongPress: () -> Void

    private var isCompact: Bool { rowHeight < 120 }
    private var circleSize: CGFloat { isCompact ? 32 : 50 }
    private var initialFontSize: CGFloat { isCompact ? 14 : 20 }
    private var scoreFontSize: CGFloat { isCompact ? 18 : 26 }
    private var verticalPadding: CGFloat { isCompact ? 6 : 12 }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: isCompact ? 4 : 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: circleSize, height: circleSize)
                    Circle()
                        .stroke(color, lineWidth: isCompact ? 2 : 2.5)
                        .frame(width: circleSize, height: circleSize)
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: initialFontSize, weight: .bold))
                        .foregroundStyle(color)
                }
                Text(name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(color)
                Text("\(score)")
                    .font(.system(size: scoreFontSize, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(color)
                Text("pts")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(color.opacity(0.85))
            }
            .frame(minHeight: 0)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity)
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
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
