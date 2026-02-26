//
//  FavoritesManager.swift
//  VibeMaster
//

import Foundation

final class FavoritesManager {
    static let shared = FavoritesManager()
    private let key = "vibemaster_favorite_playlists"
    private let defaults = UserDefaults.standard

    func load() -> [DeezerPlaylistItem] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DeezerPlaylistItem].self, from: data) else {
            return []
        }
        return decoded
    }

    func add(_ item: DeezerPlaylistItem) {
        var list = load()
        if !list.contains(where: { $0.id == item.id }) {
            list.append(item)
            save(list)
        }
    }

    func remove(id: Int) {
        var list = load()
        list.removeAll { $0.id == id }
        save(list)
    }

    func contains(id: Int) -> Bool {
        load().contains { $0.id == id }
    }

    private func save(_ list: [DeezerPlaylistItem]) {
        if let data = try? JSONEncoder().encode(list) {
            defaults.set(data, forKey: key)
        }
    }
}
