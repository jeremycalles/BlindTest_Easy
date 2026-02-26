//
//  LastGameState.swift
//  VibeMaster
//
//  Persists last-used player names for pre-filling Setup.
//

import Foundation

enum LastGameState {
    private static let key = "vibemaster_last_player_names"
    private static let defaults = UserDefaults.standard

    static func loadPlayerNames() -> [String] {
        guard let data = defaults.data(forKey: key),
              let names = try? JSONDecoder().decode([String].self, from: data),
              !names.isEmpty else {
            return []
        }
        return names
    }

    static func savePlayerNames(_ names: [String]) {
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !trimmed.isEmpty else { return }
        if let data = try? JSONEncoder().encode(trimmed) {
            defaults.set(data, forKey: key)
        }
    }
}
