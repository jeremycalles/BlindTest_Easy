//
//  PodiumView.swift
//  VibeMaster
//

import SwiftUI
import VibeMasterCore

// MARK: - Gold gradient used throughout the podium

private let goldGradient = LinearGradient(
    colors: [
        Color(red: 1.0, green: 0.84, blue: 0.3),
        Color(red: 0.85, green: 0.65, blue: 0.15),
        Color(red: 1.0, green: 0.78, blue: 0.2)
    ],
    startPoint: .top,
    endPoint: .bottom
)

private let silverGradient = LinearGradient(
    colors: [
        Color(red: 0.82, green: 0.84, blue: 0.88),
        Color(red: 0.62, green: 0.65, blue: 0.72)
    ],
    startPoint: .top,
    endPoint: .bottom
)

private let bronzeGradient = LinearGradient(
    colors: [
        Color(red: 0.82, green: 0.56, blue: 0.28),
        Color(red: 0.65, green: 0.42, blue: 0.18)
    ],
    startPoint: .top,
    endPoint: .bottom
)

struct PodiumView: View {
    let results: PodiumResult
    @Binding var path: [AppDestination]
    @State private var showWinnerConfetti = false
    @State private var showConfettiForRank: [Bool]
    @State private var crownScale: CGFloat = 0
    @State private var scoreOpacity: Double = 0
    @State private var rowAppeared: [Bool]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(results: PodiumResult, path: Binding<[AppDestination]>) {
        self.results = results
        _path = path
        let otherCount = max(0, results.playerScores.count - 1)
        _showConfettiForRank = State(initialValue: Array(repeating: false, count: otherCount))
        _rowAppeared = State(initialValue: Array(repeating: false, count: otherCount))
    }

    private var winner: PlayerScore? { results.playerScores.first }
    private var otherPlayers: [PlayerScore] {
        Array(results.playerScores.dropFirst())
    }

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 24) {
                    winnerSection
                    rankingSection
                    Spacer(minLength: 24)
                    newGameButton
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden()
        .preferredColorScheme(.dark)
        .onAppear(perform: triggerAnimations)
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.08, blue: 0.38),
                Color(red: 0.24, green: 0.10, blue: 0.44),
                Color(red: 0.14, green: 0.06, blue: 0.30)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            Color.clear
                .glassEffect(in: Rectangle())
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
    }

    // MARK: - Winner section

    @ViewBuilder
    private var winnerSection: some View {
        if let winner {
            VStack(spacing: 0) {
                Text(AppStrings.Podium.epicResults)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundStyle(goldGradient)
                    .tracking(3)
                    .padding(.top, 16)

                Image(systemName: "crown.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(goldGradient)
                    .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.2).opacity(0.6), radius: 16, y: 4)
                    .scaleEffect(crownScale)
                    .padding(.top, 8)

                winnerCard(winner)
                    .padding(.top, -20)
            }
            .overlay {
                if !reduceMotion {
                    ConfettiView(isActive: $showWinnerConfetti)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func winnerCard(_ player: PlayerScore) -> some View {
        VStack(spacing: 6) {
            Text(AppStrings.Podium.winner)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))

            Text(player.name.uppercased())
                .font(.title)
                .fontWeight(.black)
                .foregroundStyle(.white)

            Text("\(player.score)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(goldGradient)
                .opacity(scoreOpacity)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.3).opacity(0.4),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Ranking rows

    @ViewBuilder
    private var rankingSection: some View {
        if !otherPlayers.isEmpty {
            VStack(spacing: 10) {
                ForEach(Array(otherPlayers.enumerated()), id: \.element.name) { index, ps in
                    rankRow(player: ps, rank: index + 2, animationIndex: index)
                        .opacity(rowAppeared.indices.contains(index) && rowAppeared[index] ? 1 : 0)
                        .offset(y: rowAppeared.indices.contains(index) && rowAppeared[index] ? 0 : 20)
                        .overlay {
                            if !reduceMotion && index < showConfettiForRank.count {
                                ConfettiView(isActive: Binding(
                                    get: { showConfettiForRank[index] },
                                    set: { new in
                                        var updated = showConfettiForRank
                                        if index < updated.count { updated[index] = new }
                                        showConfettiForRank = updated
                                    }
                                ))
                                .allowsHitTesting(false)
                            }
                        }
                }
            }
        }
    }

    private func rankRow(player: PlayerScore, rank: Int, animationIndex: Int) -> some View {
        HStack(spacing: 12) {
            rankBadge(rank: rank)

            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(player.name.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(AppStrings.Podium.scoreDisplay(player.score))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func rankBadge(rank: Int) -> some View {
        ZStack {
            if rank <= 3 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(rank == 2 ? silverGradient : bronzeGradient)

                Text(rankOrdinal(rank))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: 6)
            } else {
                Text(rankOrdinal(rank))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(width: 44, height: 36)
    }

    private func rankOrdinal(_ rank: Int) -> String {
        let locale = Locale.current
        if locale.language.languageCode?.identifier == "fr" {
            return rank == 1 ? "1er" : "\(rank)e"
        }
        switch rank {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(rank)th"
        }
    }

    // MARK: - New Game button

    private var newGameButton: some View {
        Button {
            HapticManager.medium()
            path = [.dashboard]
        } label: {
            Text(AppStrings.Podium.newGame.uppercased())
                .font(.headline)
                .fontWeight(.bold)
                .tracking(1.5)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.25), .white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Animations

    private func triggerAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            HapticManager.playApplause()
        }

        if reduceMotion {
            crownScale = 1
            scoreOpacity = 1
            for i in rowAppeared.indices { rowAppeared[i] = true }
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
            crownScale = 1
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
            scoreOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showWinnerConfetti = true
        }

        let n = otherPlayers.count
        for i in 0..<n {
            let idx = i
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double(i) * 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    if idx < rowAppeared.count { rowAppeared[idx] = true }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 + Double(i) * 0.5) {
                if idx < showConfettiForRank.count {
                    var updated = showConfettiForRank
                    updated[idx] = true
                    showConfettiForRank = updated
                }
            }
        }
    }
}

// MARK: - Previews

private extension PodiumView {
    static var previewResult: PodiumResult {
        let config = GameConfig(tracks: [], playerNames: ["Player 1", "Alice", "Bob", "Charlie"], timerSeconds: 15, mcPlaysMode: false)
        return PodiumResult(
            playerScores: [
                PlayerScore(name: "Player 1", score: 24),
                PlayerScore(name: "Alice", score: 18),
                PlayerScore(name: "Bob", score: 12),
                PlayerScore(name: "Charlie", score: 7)
            ],
            config: config
        )
    }
}

#Preview("PodiumView") {
    NavigationStack {
        PodiumView(results: PodiumView.previewResult, path: .constant([]))
    }
}
