//
//  DeezerAPIService.swift
//  VibeMaster
//

import Foundation
import VibeMasterCore

enum DeezerAPIError: Error, Equatable {
    case invalidURL
    case serverError(Int)
    case quotaExceeded
}

struct DeezerAPIErrorPayload: Codable {
    let type: String?
    let message: String?
    let code: Int?
}

struct DeezerAPIErrorResponse: Codable {
    let error: DeezerAPIErrorPayload?
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

private let deezerSession: URLSession = {
    let c = URLSessionConfiguration.default
    c.timeoutIntervalForRequest = 15
    return URLSession(configuration: c)
}()

actor DeezerAPIService {
    static let shared = DeezerAPIService()
    private let base = "https://api.deezer.com"

    private static let chartTTL: TimeInterval = 300   // 5 min
    private static let searchTTL: TimeInterval = 300   // 5 min
    private static let playlistDetailTTL: TimeInterval = 1800 // 30 min

    private var chartCache: ([DeezerPlaylistItem], Date)?
    private var searchCache: [String: ([DeezerPlaylistItem], Date)] = [:]
    private var playlistDetailCache: [Int: ([Track], Date)] = [:]

    private func checkQuotaError(data: Data) throws {
        guard let errResp = try? JSONDecoder().decode(DeezerAPIErrorResponse.self, from: data),
              let msg = errResp.error?.message?.lowercased() else { return }
        if msg.contains("quota") || msg.contains("limit exceeded") {
            throw DeezerAPIError.quotaExceeded
        }
        if errResp.error?.code == 4 {
            throw DeezerAPIError.quotaExceeded
        }
    }

    func chartPlaylists() async throws -> [DeezerPlaylistItem] {
        if let cached = chartCache, cached.1 > Date() { return cached.0 }
        let url = URL(string: "\(base)/chart/0/playlists")!
        let (data, resp) = try await deezerSession.data(from: url)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw DeezerAPIError.serverError(http.statusCode)
        }
        try checkQuotaError(data: data)
        let decoded = try JSONDecoder().decode(DeezerChartPlaylistsResponse.self, from: data)
        chartCache = (decoded.data, Date().addingTimeInterval(Self.chartTTL))
        return decoded.data
    }

    func searchPlaylists(query: String) async throws -> [DeezerPlaylistItem] {
        let key = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let cached = searchCache[key], cached.1 > Date() { return cached.0 }
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(base)/search/playlist?q=\(encoded)") else {
            throw DeezerAPIError.invalidURL
        }
        let (data, resp) = try await deezerSession.data(from: url)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw DeezerAPIError.serverError(http.statusCode)
        }
        try checkQuotaError(data: data)
        let decoded = try JSONDecoder().decode(DeezerSearchPlaylistsResponse.self, from: data)
        searchCache[key] = (decoded.data, Date().addingTimeInterval(Self.searchTTL))
        return decoded.data
    }

    func playlistDetail(id: Int) async throws -> [Track] {
        if let cached = playlistDetailCache[id], cached.1 > Date() { return cached.0 }
        let url = URL(string: "\(base)/playlist/\(id)")!
        let (data, resp) = try await deezerSession.data(from: url)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw DeezerAPIError.serverError(http.statusCode)
        }
        try checkQuotaError(data: data)
        let decoded = try JSONDecoder().decode(DeezerPlaylistResponse.self, from: data)
        let tracks = decoded.tracks.data.compactMap { dto -> Track? in
            guard !dto.preview.isEmpty else { return nil }
            return Track(
                id: dto.id,
                title: dto.title,
                preview: dto.preview,
                artist: Artist(name: dto.artist.name, picture_medium: dto.artist.picture_medium ?? ""),
                album: Album(cover_medium: dto.album.cover_medium)
            )
        }
        playlistDetailCache[id] = (tracks, Date().addingTimeInterval(Self.playlistDetailTTL))
        return tracks
    }
}
