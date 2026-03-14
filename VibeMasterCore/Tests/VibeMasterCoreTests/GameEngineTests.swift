//
//  GameEngineTests.swift
//  VibeMasterCoreTests
//

import XCTest
import VibeMasterCore

@MainActor
final class GameEngineTests: XCTestCase {

    private func makeTrack(trackId: Int, preview: String? = nil) -> Track {
        Track(
            id: trackId,
            title: "Track \(trackId)",
            preview: preview ?? "https://example.com/\(trackId).mp3",
            artist: Artist(name: "Artist \(trackId)", picture_medium: ""),
            album: Album(cover_medium: "")
        )
    }

    private func makeConfig(
        trackCount: Int = 2,
        playerNames: [String] = ["Alice", "Bob"],
        timerSeconds: Int = 5
    ) -> GameConfig {
        let tracks = (0..<trackCount).map { makeTrack(trackId: $0) }
        return GameConfig(
            tracks: tracks,
            playerNames: playerNames,
            timerSeconds: timerSeconds,
            mcPlaysMode: false
        )
    }

    func testScoresInitializedToZero() async {
        let config = makeConfig()
        let mock = MockAudioPlayback()
        var timerEndCalls = 0
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: { timerEndCalls += 1 },
            onTimerTick: { _ in }
        )
        XCTAssertEqual(engine.scores["Alice"], 0)
        XCTAssertEqual(engine.scores["Bob"], 0)
    }

    func testAddPointIncrementsScore() async {
        let config = makeConfig()
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        engine.addPoint(playerName: "Alice")
        XCTAssertEqual(engine.scores["Alice"], 1)
        engine.addPoint(playerName: "Alice")
        XCTAssertEqual(engine.scores["Alice"], 2)
        engine.addPoint(playerName: "Bob")
        XCTAssertEqual(engine.scores["Bob"], 1)
    }

    func testAddPointsAddsValue() async {
        let config = makeConfig()
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        engine.addPoints(3, playerName: "Alice")
        XCTAssertEqual(engine.scores["Alice"], 3)
        engine.addPoints(-1, playerName: "Alice")
        XCTAssertEqual(engine.scores["Alice"], 2)
    }

    func testBuildPodiumResultOrdersByScoreDescending() async {
        let config = makeConfig()
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        engine.addPoint(playerName: "Bob")
        engine.addPoint(playerName: "Bob")
        engine.addPoint(playerName: "Alice")
        let result = engine.buildPodiumResult()
        XCTAssertEqual(result.playerScores.count, 2)
        XCTAssertEqual(result.playerScores[0].name, "Bob")
        XCTAssertEqual(result.playerScores[0].score, 2)
        XCTAssertEqual(result.playerScores[1].name, "Alice")
        XCTAssertEqual(result.playerScores[1].score, 1)
    }

    func testBuildPodiumResultPreservesConfig() async {
        let config = makeConfig(playerNames: ["A", "B", "C"])
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        let result = engine.buildPodiumResult()
        XCTAssertEqual(result.config.playerNames, ["A", "B", "C"])
        XCTAssertEqual(result.playerScores.map(\.name), ["A", "B", "C"])
    }

    func testStartRoundLoadsTrackAndStartsPlaying() async {
        let config = makeConfig()
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        engine.startRound()
        XCTAssertEqual(mock.loadURL, config.tracks[0].preview)
        XCTAssertEqual(mock.playCount, 1)
        XCTAssertTrue(engine.isPlaying)
        XCTAssertFalse(engine.isRevealed)
        XCTAssertEqual(engine.timeRemaining, config.timerSeconds)
    }

    func testRevealSetsRoundEndedAndCallsOnTimerEnd() async {
        let config = makeConfig()
        let mock = MockAudioPlayback()
        var timerEndCalls = 0
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: { timerEndCalls += 1 },
            onTimerTick: { _ in }
        )
        engine.startRound()
        engine.reveal()
        XCTAssertEqual(timerEndCalls, 1)
        XCTAssertTrue(engine.isRevealed)
        XCTAssertTrue(engine.roundEnded)
        XCTAssertEqual(mock.duckAndFadeOutCalls, 1)
    }

    func testNextTrackIncrementsIndexAndStartsNextRound() async {
        let config = makeConfig(trackCount: 3)
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        engine.startRound()
        XCTAssertEqual(engine.currentTrackIndex, 0)
        engine.reveal()
        engine.nextTrack()
        XCTAssertEqual(engine.currentTrackIndex, 1)
        XCTAssertEqual(mock.loadURL, config.tracks[1].preview)
        engine.reveal()
        engine.nextTrack()
        XCTAssertEqual(engine.currentTrackIndex, 2)
    }

    func testPointsThisSongInitializedToZero() async {
        let config = makeConfig()
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        XCTAssertEqual(engine.pointsThisSong["Alice"], 0)
        XCTAssertEqual(engine.pointsThisSong["Bob"], 0)
    }

    func testAddPointIncrementsPointsThisSong() async {
        let config = makeConfig()
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        engine.addPoint(playerName: "Alice")
        XCTAssertEqual(engine.pointsThisSong["Alice"], 1)
        engine.addPoint(playerName: "Alice")
        XCTAssertEqual(engine.pointsThisSong["Alice"], 2)
        XCTAssertEqual(engine.pointsThisSong["Bob"], 0)
    }

    func testAddPointsUpdatesPointsThisSong() async {
        let config = makeConfig()
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        engine.addPoints(3, playerName: "Alice")
        XCTAssertEqual(engine.pointsThisSong["Alice"], 3)
        engine.addPoints(-1, playerName: "Alice")
        XCTAssertEqual(engine.pointsThisSong["Alice"], 2)
    }

    func testPointsThisSongResetsOnNextTrack() async {
        let config = makeConfig(trackCount: 3)
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        engine.startRound()
        engine.addPoint(playerName: "Alice")
        engine.addPoint(playerName: "Alice")
        engine.addPoint(playerName: "Bob")
        XCTAssertEqual(engine.pointsThisSong["Alice"], 2)
        XCTAssertEqual(engine.pointsThisSong["Bob"], 1)
        XCTAssertEqual(engine.scores["Alice"], 2)
        XCTAssertEqual(engine.scores["Bob"], 1)

        engine.reveal()
        engine.nextTrack()

        XCTAssertEqual(engine.pointsThisSong["Alice"], 0)
        XCTAssertEqual(engine.pointsThisSong["Bob"], 0)
        XCTAssertEqual(engine.scores["Alice"], 2, "Total scores should persist across songs")
        XCTAssertEqual(engine.scores["Bob"], 1, "Total scores should persist across songs")
    }

    func testCurrentTrackReturnsNilWhenIndexOutOfBounds() async {
        let config = makeConfig(trackCount: 1)
        let mock = MockAudioPlayback()
        let engine = GameEngine(
            config: config,
            audio: mock,
            onTimerEnd: {},
            onTimerTick: { _ in }
        )
        XCTAssertNotNil(engine.currentTrack)
        engine.nextTrack()
        XCTAssertNil(engine.currentTrack)
    }
}
