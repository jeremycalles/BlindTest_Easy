//
//  GameConfig.swift
//  VibeMasterCore
//
//  GameConfig, PlayerScore, PodiumResult (Hashable)
//

import Foundation

public struct GameConfig: Hashable, Sendable {
    public let tracks: [Track]
    public let playerNames: [String]
    public let timerSeconds: Int
    public let mcPlaysMode: Bool

    public init(tracks: [Track], playerNames: [String], timerSeconds: Int, mcPlaysMode: Bool) {
        self.tracks = tracks
        self.playerNames = playerNames
        self.timerSeconds = timerSeconds
        self.mcPlaysMode = mcPlaysMode
    }
}

public struct PlayerScore: Hashable, Sendable {
    public let name: String
    public var score: Int

    public init(name: String, score: Int) {
        self.name = name
        self.score = score
    }
}

public struct PodiumResult: Hashable, Sendable {
    public let playerScores: [PlayerScore]
    public let config: GameConfig

    public init(playerScores: [PlayerScore], config: GameConfig) {
        self.playerScores = playerScores
        self.config = config
    }
}
