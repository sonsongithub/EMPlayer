//
//  CollectionType.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

enum CollectionType: String, Decodable, Encodable {
    case musicAlbum = "musicalbum"
    case audioBooks = "audiobooks"
    case books = "books"
    case boxSets = "boxsets"
    case games = "games"
    case homeVideos = "homevideos"
    case liveTv = "livetv"
    case movies = "movies"
    case music = "music"
    case musicVideos = "musicvideos"
    case photos = "photos"
    case playlists = "playlists"
    case trailers = "trailers"
    case tvShows = "tvshows"
    case unknown
    
    init(from decoder: Decoder) throws {
        let label = try decoder.singleValueContainer().decode(String.self).lowercased()
        self = CollectionType(rawValue: label) ?? .unknown
    }
}
