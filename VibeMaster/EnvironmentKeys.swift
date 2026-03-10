//
//  EnvironmentKeys.swift
//  VibeMaster
//
//  SwiftUI environment keys for dependency injection (e.g. audio service for tests).
//

import SwiftUI
import VibeMasterCore

private enum AudioPlaybackServiceKey: EnvironmentKey {
    static let defaultValue: AudioPlaybackService = AudioPlaybackService.shared
}

extension EnvironmentValues {
    var audioPlaybackService: AudioPlaybackService {
        get { self[AudioPlaybackServiceKey.self] }
        set { self[AudioPlaybackServiceKey.self] = newValue }
    }
}
