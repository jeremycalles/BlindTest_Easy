//
//  MockAudioPlayback.swift
//  VibeMasterCoreTests
//

import Foundation
import VibeMasterCore

final class MockAudioPlayback: AudioPlaybackProtocol {
    static func configureSession() {}

    var loadURL: String?
    var playCount = 0
    var pauseCount = 0
    var stopCount = 0
    var duckAndFadeOutCalls = 0

    func load(url: String) {
        loadURL = url
    }

    func play() {
        playCount += 1
    }

    func pause() {
        pauseCount += 1
    }

    func stop() {
        stopCount += 1
    }

    func duckAndFadeOut(duration: TimeInterval, completion: @escaping () -> Void) {
        duckAndFadeOutCalls += 1
        completion()
    }
}
