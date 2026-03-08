//
//  HapticManager.swift
//  VibeMaster
//
//  Minimal UIKit dependency: programmatic haptic feedback. SwiftUI’s SensoryFeedback
//  requires a view-level trigger; this singleton is used from ViewModels and views
//  for taps and timer-end feedback. Acceptable exception for “SwiftUI-only” UI.
//

import UIKit
import AVFoundation
import AudioToolbox

enum HapticManager {
    /// Retain chime player so it isn’t deallocated before playback finishes.
    private static var chimePlayer: AVAudioPlayer?

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    /// Plays countdown chime (chime.wav) at 3, 2, 1 seconds left.
    static func timerTick(secondsLeft: Int) {
        _ = playChime(resource: "chime")
    }
    /// Plays timer-end chime (chime_high.wav, 2 semitones up) and medium haptic. Call when the round timer reaches zero.
    static func timerEnd() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if !playChime(resource: "chime_high") {
            _ = playChime(resource: "chime")
        }
        if chimePlayer == nil {
            AudioServicesPlaySystemSound(1075)
        }
    }
    /// Plays bundled WAV by resource name. Returns true if played.
    private static func playChime(resource: String) -> Bool {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else { return false }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        chimePlayer = try? AVAudioPlayer(contentsOf: url)
        chimePlayer?.volume = 1.0
        chimePlayer?.prepareToPlay()
        chimePlayer?.play()
        return chimePlayer != nil
    }
}
