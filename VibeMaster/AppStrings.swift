//
//  AppStrings.swift
//  VibeMaster
//
//  Centralized localizable strings and error messages for consistency and future localization.
//

import Foundation

enum AppStrings {
    enum Errors {
        static let quotaExceeded = String(localized: "error.quota_exceeded")
        static let loadPlaylists = String(localized: "error.load_playlists")
        static let loadResults = String(localized: "error.load_results")
        static let loadTracks = String(localized: "error.load_tracks")
    }

    enum Common {
        static let retry = String(localized: "common.retry")
        static let cancel = String(localized: "common.cancel")
    }

    enum Splash {
        static let appName = String(localized: "splash.app_name")
        static let startButton = String(localized: "splash.start_button")
        static let poweredByDeezer = String(localized: "splash.powered_by_deezer")
    }

    enum Setup {
        static let loading = String(localized: "setup.loading")
        static let errorTitle = String(localized: "setup.error_title")
        static let noTracks = String(localized: "setup.no_tracks")
        static let title = String(localized: "setup.title")
        static let playersSection = String(localized: "setup.players_section")
        static func playerPlaceholder(_ index: Int) -> String {
            String(format: String(localized: "setup.player_placeholder"), index)
        }
        static let addPlayer = String(localized: "setup.add_player")
        static let addPlayerButton = String(localized: "setup.add_player_button")
        static let timerSection = String(localized: "setup.timer_section")
        static func timerSeconds(_ seconds: Int) -> String {
            String(format: String(localized: "setup.timer_seconds"), seconds)
        }
        static let tracksCountSection = String(localized: "setup.tracks_count_section")
        static func tracksCountValue(current: Int, total: Int) -> String {
            String(format: String(localized: "setup.tracks_count_value"), current, total)
        }
        static let mcModeSection = String(localized: "setup.mc_mode_section")
        static let mcModeSubtitle = String(localized: "setup.mc_mode_subtitle")
        static let mcPlaysToggle = String(localized: "setup.mc_plays_toggle")
        static let startGame = String(localized: "setup.start_game")
    }

    enum Podium {
        static let epicResults = String(localized: "podium.epic_results")
        static let winner = String(localized: "podium.winner")
        static let subtitle = String(localized: "podium.subtitle")
        static let pointsAbbrev = String(localized: "podium.points_abbrev")
        static func scoreDisplay(_ score: Int) -> String {
            String(format: String(localized: "podium.score_display"), score)
        }
        static let newGame = String(localized: "podium.new_game")
    }

    enum Dashboard {
        static let myBlindTests = String(localized: "dashboard.my_blind_tests")
        static let topPlaylists = String(localized: "dashboard.top_playlists")
        static let searchPlaylistsPrompt = String(localized: "dashboard.search_playlists_prompt")
        static let home = String(localized: "dashboard.home")
        static let results = String(localized: "dashboard.results")
        static let noResults = String(localized: "dashboard.no_results")
        static let addFavoritesHint = String(localized: "dashboard.add_favorites_hint")
        static func trackCount(_ n: Int) -> String {
            String(format: String(localized: "dashboard.track_count"), n)
        }
        static let deezerAccessibilityHint = String(localized: "dashboard.deezer_accessibility_hint")
    }

    enum Game {
        static let stopTitle = String(localized: "game.stop_title")
        static let stopMessage = String(localized: "game.stop_message")
        static let stopButton = String(localized: "game.stop_button")
        static let stopHint = String(localized: "game.stop_hint")
        static func trackHeader(current: Int, total: Int) -> String {
            String(format: String(localized: "game.track_header"), current, total)
        }
        static let next = String(localized: "game.next")
        static let finish = String(localized: "game.finish")
        static let timeUp = String(localized: "game.time_up")
        static let pause = String(localized: "game.pause")
        static let play = String(localized: "game.play")
        static let playPauseHint = String(localized: "game.play_pause_hint")
        static let nextTrackLabel = String(localized: "game.next_track_label")
        static let nextTrackHint = String(localized: "game.next_track_hint")
        static let viewPodium = String(localized: "game.view_podium")
        static let viewPodiumHint = String(localized: "game.view_podium_hint")
        static func playerTileLabel(name: String, score: Int) -> String {
            String(format: String(localized: "game.player_tile_label"), name, score)
        }
        static let playerTileHint = String(localized: "game.player_tile_hint")
        static func pointsThisSong(_ count: Int) -> String {
            String(format: String(localized: "game.points_this_song"), count)
        }
        static func pointsThisSongAccessibility(_ count: Int) -> String {
            String(format: String(localized: "game.points_this_song_accessibility"), count)
        }
    }
}
