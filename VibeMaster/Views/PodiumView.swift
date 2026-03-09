//
//  PodiumView.swift
//  VibeMaster
//

import SwiftUI
import VibeMasterCore

struct PodiumView: View {
    let results: PodiumResult
    @Binding var path: [AppDestination]
    @State private var showWinnerConfetti = false
    @State private var showConfettiForRank: [Bool]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(results: PodiumResult, path: Binding<[AppDestination]>) {
        self.results = results
        _path = path
        let otherCount = max(0, results.playerScores.count - 1)
        _showConfettiForRank = State(initialValue: Array(repeating: false, count: otherCount))
    }

    private var winner: PlayerScore? { results.playerScores.first }
    private var otherPlayers: [PlayerScore] {
        Array(results.playerScores.dropFirst())
    }

    var body: some View {
        ZStack {
            // Deep purple background with optional gradient
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.12, blue: 0.38),
                    Color(red: 0.28, green: 0.14, blue: 0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .overlay {
                Color.clear
                    .glassEffect(in: Rectangle())
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }

            ScrollView {
                VStack(spacing: 24) {
                    // Title block
                    VStack(spacing: 8) {
                        Text("RÉSULTATS ÉPIQUES")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.95))

                        Text("Et le BlindTest Easy est...")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Winner card
                    if let winner = winner {
                        winnerCard(winner)
                            .overlay {
                                if !reduceMotion {
                                    ConfettiView(isActive: $showWinnerConfetti)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    // Other players ranking card
                    if !otherPlayers.isEmpty {
                        rankingCard
                    }

                    Spacer(minLength: 24)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button("Une nouvelle partie!") {
                            HapticManager.medium()
                            path = [.dashboard]
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            // Applause when results screen appears (plays full file)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                HapticManager.playApplause()
            }
            guard !reduceMotion else { return }
            // Winner card confetti after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showWinnerConfetti = true
            }
            // Each ranking row confetti after winner (2s, 3s, 4s...)
            let n = otherPlayers.count
            for i in 0..<n {
                let rankIndex = i
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 + Double(i)) {
                    if rankIndex < showConfettiForRank.count {
                        var updated = showConfettiForRank
                        updated[rankIndex] = true
                        showConfettiForRank = updated
                    }
                }
            }
        }
    }

    private func winnerCard(_ player: PlayerScore) -> some View {
        let useFloat = !reduceMotion
        return VStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(white: 0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(player.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("\(player.score) pts")
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(.white)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .offset(y: useFloat ? -4 : 0)
        .animation(useFloat ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: useFloat)
    }

    private var rankingCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(otherPlayers.enumerated()), id: \.element.name) { index, ps in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Text(String(ps.name.prefix(1)).uppercased())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    Text(ps.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(ps.score)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
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

                if index < otherPlayers.count - 1 {
                    Rectangle()
                        .fill(.white.opacity(0.15))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                }
            }
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }
}
