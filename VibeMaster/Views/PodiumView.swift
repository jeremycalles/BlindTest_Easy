//
//  PodiumView.swift
//  VibeMaster
//

import SwiftUI

struct PodiumView: View {
    let results: PodiumResult
    @Binding var path: [AppDestination]
    @State private var showConfetti = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            .overlay(.ultraThinMaterial)

            if showConfetti && !reduceMotion {
                ConfettiOverlay()
                    .allowsHitTesting(false)
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

                        Text("Et le VibeMaster est...")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Winner card
                    if let winner = winner {
                        winnerCard(winner)
                    }

                    // Other players ranking card
                    if !otherPlayers.isEmpty {
                        rankingCard
                    }

                    Spacer(minLength: 24)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button("Retour à l'accueil") {
                            HapticManager.medium()
                            path = [.dashboard]
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            if !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showConfetti = false
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
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

                if index < otherPlayers.count - 1 {
                    Rectangle()
                        .fill(.white.opacity(0.15))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }
}

struct ConfettiOverlay: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<30, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill([Color.orange, .purple, .pink, .yellow, .cyan, .white].randomElement()!)
                    .frame(width: CGFloat.random(in: 4...10), height: CGFloat.random(in: 4...10))
                    .position(x: CGFloat.random(in: 0...geo.size.width), y: -20)
            }
        }
        .allowsHitTesting(false)
    }
}
