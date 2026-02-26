//
//  GameConfig.swift
//  VibeMaster
//
//  GameConfig, PlayerScore, PodiumResult (Hashable)
//

import Foundation

struct GameConfig: Hashable {
    let tracks: [Track]
    let playerNames: [String]
    let timerSeconds: Int
    let mcPlaysMode: Bool
}

struct PlayerScore: Hashable {
    let name: String
    var score: Int
}

struct PodiumResult: Hashable {
    let playerScores: [PlayerScore]
    let config: GameConfig
}
