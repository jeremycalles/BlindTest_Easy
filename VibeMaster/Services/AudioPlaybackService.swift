//
//  AudioPlaybackService.swift
//  VibeMaster
//

import Foundation
import AVFoundation
import VibeMasterCore

final class AudioPlaybackService: AudioPlaybackProtocol {
    static let shared = AudioPlaybackService()
    private var player: AVPlayer?
    private var fadeTimer: Timer?

    static func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    func load(url: String) {
        stop()
        guard let u = URL(string: url) else { return }
        player = AVPlayer(url: u)
        player?.volume = 1.0
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        player?.pause()
        player = nil
    }

    func duckAndFadeOut(duration: TimeInterval = 20, completion: @escaping () -> Void) {
        fadeTimer?.invalidate()
        fadeTimer = nil
        let steps = 20
        let stepDuration = duration / Double(steps)
        var step = 0
        let timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] t in
            step += 1
            let progress = Float(step) / Float(steps)
            self?.player?.volume = 1.0 * (1 - progress)
            if step >= steps {
                t.invalidate()
                self?.fadeTimer = nil
                completion()
            }
        }
        fadeTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
}
