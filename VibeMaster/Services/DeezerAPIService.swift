//
//  DeezerAPIService.swift
//  VibeMaster
//

import Foundation
import VibeMasterCore

enum DeezerAPIError: Error {
    case invalidURL
    case serverError(Int)
}

struct DeezerPlaylistItem: Codable {
    let id: Int
    let title: String
    let picture_medium: String?
    let nb_tracks: Int?
}

struct DeezerSearchPlaylistsResponse: Codable {
    let data: [DeezerPlaylistItem]
}

struct DeezerChartPlaylistsResponse: Codable {
    let data: [DeezerPlaylistItem]
    let total: Int?
}

struct DeezerTracksContainer: Codable {
    let data: [DeezerTrackDTO]
}

struct DeezerTrackDTO: Codable {
    let id: Int
    let title: String
    let preview: String
    let artist: DeezerArtistDTO
    let album: DeezerAlbumDTO
}

struct DeezerArtistDTO: Codable {
    let name: String
    let picture_medium: String?
}

struct DeezerAlbumDTO: Codable {
    let cover_medium: String
}

struct DeezerPlaylistResponse: Codable {
    let tracks: DeezerTracksContainer
}

final class DeezerAPIService {
    static let shared = DeezerAPIService()
    private let base = "https://api.deezer.com"
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        return URLSession(configuration: c)
    }()

    func chartPlaylists() async throws -> [DeezerPlaylistItem] {
        let url = URL(string: "\(base)/chart/0/playlists")!
        let (data, _) = try await session.data(from: url)
        let decoded = try JSONDecoder().decode(DeezerChartPlaylistsResponse.self, from: data)
        return decoded.data
    }

    func searchPlaylists(query: String) async throws -> [DeezerPlaylistItem] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(base)/search/playlist?q=\(encoded)") else {
            throw DeezerAPIError.invalidURL
        }
        let (data, resp) = try await session.data(from: url)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw DeezerAPIError.serverError(http.statusCode)
        }
        let decoded = try JSONDecoder().decode(DeezerSearchPlaylistsResponse.self, from: data)
        return decoded.data
    }

    func playlistDetail(id: Int) async throws -> [Track] {
        let url = URL(string: "\(base)/playlist/\(id)")!
        let (data, _) = try await session.data(from: url)
        let decoded = try JSONDecoder().decode(DeezerPlaylistResponse.self, from: data)
        return decoded.tracks.data.compactMap { dto -> Track? in
            guard !dto.preview.isEmpty else { return nil }
            return Track(
                id: dto.id,
                title: dto.title,
                preview: dto.preview,
                artist: Artist(name: dto.artist.name, picture_medium: dto.artist.picture_medium ?? ""),
                album: Album(cover_medium: dto.album.cover_medium)
            )
        }
    }
}
