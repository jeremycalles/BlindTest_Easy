//
//  HapticManager.swift
//  VibeMaster
//
//  Minimal UIKit dependency: programmatic haptic feedback. SwiftUI’s SensoryFeedback
//  requires a view-level trigger; this singleton is used from ViewModels and views
//  for taps and timer-end feedback. Acceptable exception for “SwiftUI-only” UI.
//

import UIKit
import AudioToolbox

enum HapticManager {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    /// Plays timer-end sound (system 1075) and medium haptic. Call when the round timer reaches zero.
    static func timerEnd() {
        AudioServicesPlaySystemSound(1104)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
