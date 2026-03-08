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
    /// Plays timer-end chime (bundled chime.wav) and medium haptic. Call when the round timer reaches zero.
    /// Falls back to system sound 1075 if the bundled chime is missing.
    static func timerEnd() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        guard let url = Bundle.main.url(forResource: "chime", withExtension: "wav") else {
            AudioServicesPlaySystemSound(1075)
            return
        }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        chimePlayer = try? AVAudioPlayer(contentsOf: url)
        chimePlayer?.volume = 1.0
        chimePlayer?.prepareToPlay()
        chimePlayer?.play()
    }
}
