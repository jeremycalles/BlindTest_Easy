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
        static let startButton = String(localized: "splash.start_button")
        static let poweredByDeezer = String(localized: "splash.powered_by_deezer")
    }

    enum Dashboard {
        static let myBlindTests = String(localized: "dashboard.my_blind_tests")
        static let topPlaylists = String(localized: "dashboard.top_playlists")
        static let searchPlaylistsPrompt = String(localized: "dashboard.search_playlists_prompt")
        static let home = String(localized: "dashboard.home")
        static let results = String(localized: "dashboard.results")
        static let noResults = String(localized: "dashboard.no_results")
        static let addFavoritesHint = String(localized: "dashboard.add_favorites_hint")
    }

    enum Game {
        static let stopTitle = String(localized: "game.stop_title")
        static let stopMessage = String(localized: "game.stop_message")
        static let stopButton = String(localized: "game.stop_button")
        static let next = String(localized: "game.next")
        static let finish = String(localized: "game.finish")
        static let timeUp = String(localized: "game.time_up")
    }
}
