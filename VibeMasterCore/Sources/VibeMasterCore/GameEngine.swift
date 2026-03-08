//
//  GameEngine.swift
//  VibeMasterCore
//
//  @MainActor ObservableObject; game state + audio/timer. Injected: audio service and onTimerEnd callback.
//

import Foundation
import Combine

@MainActor
public final class GameEngine: ObservableObject {
    private let config: GameConfig
    private let audio: AudioPlaybackProtocol
    private let onTimerEnd: () -> Void
    private let onTimerTick: (Int) -> Void
    private var timerTask: Task<Void, Never>?

    @Published public private(set) var currentTrackIndex = 0
    @Published public private(set) var scores: [String: Int] = [:]
    @Published public private(set) var isPlaying = false
    @Published public private(set) var isRevealed = false
    @Published public private(set) var timeRemaining = 0
    @Published public private(set) var roundEnded = false

    public var currentTrack: Track? {
        guard currentTrackIndex >= 0, currentTrackIndex < config.tracks.count else { return nil }
        return config.tracks[currentTrackIndex]
    }

    public init(config: GameConfig, audio: AudioPlaybackProtocol, onTimerEnd: @escaping () -> Void, onTimerTick: @escaping (Int) -> Void) {
        self.config = config
        self.audio = audio
        self.onTimerEnd = onTimerEnd
        self.onTimerTick = onTimerTick
        config.playerNames.forEach { scores[$0] = 0 }
        type(of: audio).configureSession()
    }

    public func startRound() {
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
        var previousRemaining = config.timerSeconds
        timerTask = Task { @MainActor in
            for step in 0..<totalSteps {
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: stepNanoseconds)
                if Task.isCancelled { break }
                timeRemaining = max(0, config.timerSeconds - (step + 1) / 10)
                if (1...3).contains(timeRemaining) && timeRemaining != previousRemaining {
                    onTimerTick(timeRemaining)
                }
                previousRemaining = timeRemaining
                if timeRemaining == 0 {
                    reveal()
                    break
                }
            }
        }
    }

    public func togglePlayPause() {
        if isPlaying {
            timerTask?.cancel()
            audio.pause()
            isPlaying = false
        } else if currentTrackIndex < config.tracks.count && !roundEnded {
            audio.play()
            isPlaying = true
            startTimer()
        }
    }

    public func reveal() {
        onTimerEnd()
        timerTask?.cancel()
        isRevealed = true
        roundEnded = true
        audio.duckAndFadeOut(duration: 20) { }
    }

    public func addPoint(playerName: String) {
        scores[playerName, default: 0] += 1
    }

    public func addPoints(_ value: Int, playerName: String) {
        scores[playerName, default: 0] += value
    }

    public func nextTrack() {
        audio.stop()
        currentTrackIndex += 1
        if currentTrackIndex >= config.tracks.count { return }
        startRound()
    }

    public func buildPodiumResult() -> PodiumResult {
        let sorted = config.playerNames.map { PlayerScore(name: $0, score: scores[$0] ?? 0) }
            .sorted { $0.score > $1.score }
        return PodiumResult(playerScores: sorted, config: config)
    }
}
