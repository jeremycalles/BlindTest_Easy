//
//  MockPlaylistService.swift
//  VibeMaster
//

import Foundation

enum MockPlaylistService {
    static func loadTracks() async -> [Track] {
        guard let url = Bundle.main.url(forResource: "MockData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(PlaylistResponse.self, from: data) else {
            return []
        }
        return response.data
    }
}
