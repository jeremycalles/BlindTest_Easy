//
//  HapticManager.swift
//  VibeMaster
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
        AudioServicesPlaySystemSound(1075)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
