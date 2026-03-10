//
//  SplashView.swift
//  VibeMaster
//

import SwiftUI

struct SplashView: View {
    @Binding var path: [AppDestination]
    @State private var showSplashConfetti = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 72))
                    .symbolRenderingMode(.hierarchical)
                Text("BlindTest Easy")
                    .font(.largeTitle)
                    .bold()
            }
            .foregroundStyle(.white)
            Spacer()
            Button(AppStrings.Splash.startButton) {
                HapticManager.medium()
                path.append(.dashboard)
            }
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.indigo)
            .padding(.bottom, 48)
            Text(AppStrings.Splash.poweredByDeezer)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom)
        )
        .overlay {
            if showSplashConfetti && !reduceMotion {
                ConfettiView(isActive: $showSplashConfetti)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Only play confetti and applause when the splash is actually visible (path empty).
            // With path = [.dashboard] at launch, the root SplashView is still in the hierarchy
            // so onAppear runs while the user sees Dashboard — guard so we don't play there.
            guard path.isEmpty else { return }
            showSplashConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                HapticManager.playApplause()
            }
        }
    }
}
