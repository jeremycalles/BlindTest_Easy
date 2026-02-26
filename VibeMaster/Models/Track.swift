//
//  Track.swift
//  VibeMaster
//
//  Domain: Track, Artist, Album; PlaylistResponse (Codable)
//

import Foundation

struct Track: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let preview: String
    let artist: Artist
    let album: Album
}

struct Artist: Codable, Hashable {
    let name: String
    let picture_medium: String
}

struct Album: Codable, Hashable {
    let cover_medium: String
}

struct PlaylistResponse: Codable {
    let data: [Track]
}
