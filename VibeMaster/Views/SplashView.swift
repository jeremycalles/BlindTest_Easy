//
//  SplashView.swift
//  VibeMaster
//

import SwiftUI

private let particleSeeds: [(x: CGFloat, y: CGFloat, size: CGFloat)] = (0..<40).map { i -> (x: CGFloat, y: CGFloat, size: CGFloat) in
    let s = CGFloat((i * 7 + 11) % 100) / 100
    return (
        x: CGFloat((i * 13 + 17) % 100) / 100,
        y: CGFloat((i * 19 + 23) % 100) / 100,
        size: 1.5 + s * 2.5
    )
}

struct SplashView: View {
    @Binding var path: [AppDestination]
    @State private var showSplashConfetti = false
    @State private var particlesVisible = false
    @State private var orbPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.04, blue: 0.12),
                        Color(red: 0.01, green: 0.01, blue: 0.06),
                        .black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Subtle sparkle particles
                if !reduceMotion {
                    ForEach(Array(particleSeeds.enumerated()), id: \.offset) { _, p in
                        Circle()
                            .fill(.white)
                            .frame(width: p.size, height: p.size)
                            .opacity(particlesVisible ? (0.2 + p.size * 0.12) : 0)
                            .scaleEffect(particlesVisible ? 1 : 0.1)
                            .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
                    }
                }

                // Main content
                VStack(spacing: 0) {
                    Spacer()

                    // Ripple effect behind logo
                    ZStack {
                        if !reduceMotion {
                            ForEach(0..<3) { i in
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .purple.opacity(0), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 2
                                    )
                                    .frame(width: 160, height: 160)
                                    .scaleEffect(orbPulse ? 2.5 : 1.0)
                                    .opacity(orbPulse ? 0 : 0.5)
                                    .animation(
                                        .easeOut(duration: 3.0)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 0.8),
                                        value: orbPulse
                                    )
                            }
                        }
                        
                        // App Logo
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .scaleEffect(orbPulse ? 1.05 : 1.0)
                            .shadow(color: .purple.opacity(0.5), radius: 40, y: 0)
                            .shadow(color: .cyan.opacity(0.3), radius: 60, y: 0)
                    }

                    // App name
                    Text(AppStrings.Splash.appName)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.top, 24)

                    Spacer()

                    // Deezer attribution
                    DeezerAttributionBadge()
                        .padding(.bottom, 20)

                    // Glass START button
                    Button {
                        HapticManager.medium()
                        path.append(.dashboard)
                    } label: {
                        Text(AppStrings.Splash.startButton)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundStyle(.white)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 60)
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .purple.opacity(0.2), radius: 24, y: 6)
                    .shadow(color: .cyan.opacity(0.1), radius: 40, y: 8)
                    .padding(.bottom, 40)
                }
                .padding()

                if showSplashConfetti && !reduceMotion {
                    ConfettiView(isActive: $showSplashConfetti)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard path.isEmpty else { return }
            showSplashConfetti = true
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.8)) {
                    particlesVisible = true
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    orbPulse = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                HapticManager.playApplause()
            }
        }
    }
}

#Preview("SplashView") {
    SplashView(path: .constant([]))
}
