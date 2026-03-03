//
//  Track.swift
//  VibeMasterCore
//
//  Domain: Track, Artist, Album; PlaylistResponse (Codable)
//

import Foundation

public struct Track: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let preview: String
    public let artist: Artist
    public let album: Album

    public init(id: Int, title: String, preview: String, artist: Artist, album: Album) {
        self.id = id
        self.title = title
        self.preview = preview
        self.artist = artist
        self.album = album
    }
}

public struct Artist: Codable, Hashable, Sendable {
    public let name: String
    public let picture_medium: String

    public init(name: String, picture_medium: String) {
        self.name = name
        self.picture_medium = picture_medium
    }
}

public struct Album: Codable, Hashable, Sendable {
    public let cover_medium: String

    public init(cover_medium: String) {
        self.cover_medium = cover_medium
    }
}

public struct PlaylistResponse: Codable, Sendable {
    public let data: [Track]

    public init(data: [Track]) {
        self.data = data
    }
}
