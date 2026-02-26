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

    var body: some View {
        ZStack {
            Color.indigo.opacity(0.4)
                .ignoresSafeArea()
                .overlay(.ultraThinMaterial)

            if showConfetti && !reduceMotion {
                ConfettiOverlay()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 24) {
                Text("Podium")
                    .font(.largeTitle)
                    .bold()

                if let winner = results.playerScores.first {
                    winnerCard(winner)
                }

                List {
                    ForEach(Array(results.playerScores.enumerated()), id: \.element.name) { index, ps in
                        HStack {
                            Text("\(index + 1)")
                                .font(.title2)
                                .bold()
                                .frame(width: 32, alignment: .leading)
                            Text(ps.name)
                            Spacer()
                            Text("\(ps.score)")
                                .font(.headline)
                                .fontDesign(.rounded)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
                .frame(maxHeight: 280)

                Spacer()

                VStack(spacing: 12) {
                    Button("Rejouer") {
                        path.append(.game(results.config))
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .buttonStyle(.borderedProminent)

                    Button("Retour à l'accueil") {
                        path = [.dashboard]
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .buttonStyle(.bordered)
                }
            }
            .padding()
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
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                Text(String(player.name.prefix(1)).uppercased())
                    .font(.largeTitle)
                    .bold()
            }
            Text(player.name)
                .font(.title2)
                .fontWeight(.semibold)
            Text("\(player.score) point(s)")
                .font(.title3)
                .fontWeight(.heavy)
                .fontDesign(.rounded)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 32)
        .offset(y: useFloat ? -4 : 0)
        .animation(useFloat ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: useFloat)
    }
}

struct ConfettiOverlay: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<30, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill([Color.orange, .purple, .pink, .yellow, .cyan].randomElement()!)
                    .frame(width: CGFloat.random(in: 4...10), height: CGFloat.random(in: 4...10))
                    .position(x: CGFloat.random(in: 0...geo.size.width), y: -20)
            }
        }
        .allowsHitTesting(false)
    }
}
