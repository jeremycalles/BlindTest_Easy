//
//  GameEngine.swift
//  VibeMaster
//
//  @MainActor ObservableObject; game state + audio/timer
//

import Foundation
import AVFoundation

@MainActor
final class GameEngine: ObservableObject {
    private let config: GameConfig
    private let audio = AudioPlaybackService.shared
    private var timerTask: Task<Void, Never>?

    @Published private(set) var currentTrackIndex = 0
    @Published private(set) var scores: [String: Int] = [:]
    @Published private(set) var isPlaying = false
    @Published private(set) var isRevealed = false
    @Published private(set) var timeRemaining = 0
    @Published private(set) var roundEnded = false

    var currentTrack: Track? {
        guard currentTrackIndex >= 0, currentTrackIndex < config.tracks.count else { return nil }
        return config.tracks[currentTrackIndex]
    }

    init(_ config: GameConfig) {
        self.config = config
        config.playerNames.forEach { scores[$0] = 0 }
        AudioPlaybackService.configureSession()
    }

    func startRound() {
        guard currentTrackIndex < config.tracks.count else { return }
        let track = config.tracks[currentTrackIndex]
        guard !track.preview.isEmpty else { return }
        audio.load(url: track.preview)
        audio.play()
        isRevealed = false
        roundEnded = false
        timeRemaining = config.timerSeconds
        isPlaying = true
        startTimer()
    }

    private func startTimer() {
        timerTask?.cancel()
        let totalSteps = config.timerSeconds * 10
        let stepNanoseconds: UInt64 = 100_000_000
        timerTask = Task { @MainActor in
            for step in 0..<totalSteps {
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: stepNanoseconds)
                if Task.isCancelled { break }
                timeRemaining = max(0, config.timerSeconds - (step + 1) / 10)
                if timeRemaining == 0 {
                    reveal()
                    break
                }
            }
        }
    }

    func togglePlayPause() {
        if isPlaying {
            timerTask?.cancel()
            audio.pause()
        }
        isPlaying = false
    }

    func reveal() {
        HapticManager.timerEnd()
        timerTask?.cancel()
        isRevealed = true
        roundEnded = true
        audio.duckAndFadeOut(duration: 20) { }
    }

    func addPoint(playerName: String) {
        scores[playerName, default: 0] += 1
    }

    func addPoints(_ value: Int, playerName: String) {
        scores[playerName, default: 0] += value
    }

    func nextTrack() {
        audio.stop()
        currentTrackIndex += 1
        if currentTrackIndex >= config.tracks.count { return }
        startRound()
    }

    func buildPodiumResult() -> PodiumResult {
        let sorted = config.playerNames.map { PlayerScore(name: $0, score: scores[$0] ?? 0) }
            .sorted { $0.score > $1.score }
        return PodiumResult(playerScores: sorted, config: config)
    }
}
