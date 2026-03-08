//
//  GameView.swift
//  VibeMaster
//

import SwiftUI
import VibeMasterCore

struct GameView: View {
    let config: GameConfig
    @Binding var path: [AppDestination]
    @StateObject private var engine: GameEngine
    @State private var showStopGameConfirmation = false
    @State private var timerBounceScale: CGFloat = 1.0

    init(config: GameConfig, path: Binding<[AppDestination]>) {
        self.config = config
        _path = path
        _engine = StateObject(wrappedValue: GameEngine(
            config: config,
            audio: AudioPlaybackService.shared,
            onTimerEnd: { HapticManager.timerEnd() }
        ))
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
        .overlay {
            Color.clear
                .glassEffect(in: Rectangle())
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
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
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if config.mcPlaysMode && !engine.isRevealed {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground).opacity(0.95))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 12))
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
                    iconName: playerIcon(for: name),
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
        .onChange(of: engine.timeRemaining) { _, remaining in
            guard !engine.roundEnded, (1...3).contains(remaining) else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { timerBounceScale = 2.15 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { timerBounceScale = 1.0 }
            }
        }
        .onChange(of: engine.roundEnded) { _, ended in
            if ended {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { timerBounceScale = 1.35 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { timerBounceScale = 1.0 }
                }
                // When all tracks have been played, show podium automatically
                if engine.currentTrackIndex + 1 >= config.tracks.count {
                    let result = engine.buildPodiumResult()
                    path.append(.podium(result))
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
                if engine.currentTrackIndex + 1 < config.tracks.count {
                    Button("Suivant") {
                        engine.nextTrack()
                        HapticManager.medium()
                    }
                    .fontWeight(.semibold)
                    .frame(width: 90, height: 44)
                    .glassEffect(in: Capsule())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                // Last track: podium is shown automatically via onChange(roundEnded)
            }
        }
    }

    private func playerColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(red: 0.2, green: 0.6, blue: 1.0),   // Blue (Flame)
            Color(red: 1.0, green: 0.75, blue: 0.1),  // Yellow (Crown)
            Color(red: 0.2, green: 0.85, blue: 0.4),  // Green (Heart)
            Color(red: 1.0, green: 0.3, blue: 0.8),   // Pink (Shield)
            Color(red: 0.6, green: 0.3, blue: 0.9),   // Purple
            Color(red: 1.0, green: 0.4, blue: 0.2)    // Orange
        ]
        let idx = config.playerNames.firstIndex(of: name) ?? 0
        return colors[idx % colors.count]
    }
    
    private func playerIcon(for name: String) -> String {
        let icons = [
            "flame.fill",
            "crown.fill",
            "heart.fill",
            "shield.fill",
            "star.fill",
            "bolt.fill"
        ]
        let idx = config.playerNames.firstIndex(of: name) ?? 0
        return icons[idx % icons.count]
    }
}

// MARK: - Confetti

private let confettiColors: [Color] = [
    Color(red: 1, green: 0.8, blue: 0.2),
    Color(red: 1, green: 0.4, blue: 0.2),
    Color(red: 0.2, green: 0.8, blue: 0.5),
    Color(red: 0.3, green: 0.5, blue: 1),
    Color(red: 1, green: 0.4, blue: 0.7),
    Color(red: 0.9, green: 0.5, blue: 1)
]

struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var burstProgress: CGFloat = 1
    private let particleCount = 50
    private let duration: TimeInterval = 1.0

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0..<particleCount, id: \.self) { i in
                    ConfettiParticle(index: i, center: center, progress: burstProgress, colors: confettiColors)
                }
            }
            .allowsHitTesting(false)
        }
        .onAppear {
            if isActive {
                burstProgress = 0
                withAnimation(.easeOut(duration: 0.85)) { burstProgress = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { isActive = false }
                }
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                burstProgress = 0
                withAnimation(.easeOut(duration: 0.85)) { burstProgress = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { isActive = false }
                }
            }
        }
    }
}

struct ConfettiParticle: View {
    let index: Int
    let center: CGPoint
    let progress: CGFloat
    let colors: [Color]

    private var angle: Double { Double(index) * 0.14 * 2 * .pi }
    private var distance: CGFloat { 50 + CGFloat(index % 12) * 10 }
    private var endX: CGFloat { cos(angle) * distance + CGFloat(index % 7 - 3) * 10 }
    private var endY: CGFloat { sin(angle) * distance * 0.6 + CGFloat(index % 5) * 14 }
    private var delay: Double { Double(index % 6) * 0.02 }
    private var color: Color { colors[index % colors.count] }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 5, height: 5)
            .position(x: center.x + endX * progress, y: center.y + endY * progress)
            .opacity(1 - progress)
            .animation(.easeOut(duration: 0.85).delay(delay), value: progress)
    }
}

// MARK: - Player tile

struct PlayerTile: View {
    let name: String
    let score: Int
    let color: Color
    let iconName: String
    var rowHeight: CGFloat = 140
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false
    @State private var longPressConsumed = false
    @State private var showConfetti = false

    private var tileContent: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 24)
                .glassEffect(in: RoundedRectangle(cornerRadius: 24))
                .opacity(0.6)

            // Glowing border
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(color, lineWidth: 3)
                .shadow(color: color.opacity(0.8), radius: 8, x: 0, y: 0)

            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image(systemName: iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(color)
                        .shadow(color: color.opacity(0.8), radius: 6)

                    Spacer()

                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                }

                Spacer()

                Text(name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 4)
    }

    var body: some View {
        tileContent
            .scaleEffect(isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .overlay {
                if showConfetti {
                    ConfettiView(isActive: $showConfetti)
                }
            }
            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
                if pressing { longPressConsumed = false }
            }, perform: {
                longPressConsumed = true
                onLongPress()
            })
            .onTapGesture(count: 2) {
                showConfetti = true
                onDoubleTap()
            }
            .onTapGesture(count: 1) {
                if !longPressConsumed {
                    showConfetti = true
                    onTap()
                }
            }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
