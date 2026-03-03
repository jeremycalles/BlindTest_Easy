//
//  AudioPlaybackProtocol.swift
//  VibeMasterCore
//
//  Protocol for audio playback; implementation and config live in the app target.
//

import Foundation

public protocol AudioPlaybackProtocol: AnyObject {
    static func configureSession()
    func load(url: String)
    func play()
    func pause()
    func stop()
    func duckAndFadeOut(duration: TimeInterval, completion: @escaping () -> Void)
}
