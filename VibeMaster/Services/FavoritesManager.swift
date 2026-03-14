//
//  FavoritesManager.swift
//  VibeMaster
//

import Foundation

final class FavoritesManager {
    static let shared = FavoritesManager()

    /// Default playlist added on first launch: "Blind test Total 60-2026" (Deezer "Blind Test : Année 60").
    static let defaultPlaylist = DeezerPlaylistItem(
        id: 6299295304,
        title: "Blind test Total 60-2026",
        picture_medium: nil,
        nb_tracks: 110
    )

    private let key = "vibemaster_favorite_playlists"
    private let hasSeededKey = "vibemaster_has_seeded_default_playlist"
    private let defaults = UserDefaults.standard
    private var cachedList: [DeezerPlaylistItem]?

    func load() -> [DeezerPlaylistItem] {
        seedDefaultPlaylistIfNeeded()
        if let cached = cachedList { return cached }
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DeezerPlaylistItem].self, from: data) else {
            cachedList = []
            return []
        }
        cachedList = decoded
        return decoded
    }

    /// On first launch, adds the default "Blind test Total 60-2026" to Mes Blind Tests.
    private func seedDefaultPlaylistIfNeeded() {
        guard !defaults.bool(forKey: hasSeededKey) else { return }
        defaults.set(true, forKey: hasSeededKey)
        add(Self.defaultPlaylist)
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
            cachedList = list
        }
    }
}
