//
//  ItemType.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

enum ItemType: String, Decodable, Encodable {
    case audio = "audio"
    case video = "video"
    case folder = "folder"
    case episode = "episode"
    case movie = "movie"
    case trailer = "trailer"
    case adultVideo = "adultvideo"
    case musicVideo = "musicvideo"
    case boxSet = "boxset"
    case musicAlbum = "musicalbum"
    case musicArtist = "musicartist"
    case season = "season"
    case series = "series"
    case game = "game"
    case gameSystem = "gamesystem"
    case book = "book"
    case collectionFolder = "collectionfolder"
    case unknown
    
    init(from decoder: Decoder) throws {
        let label = try decoder.singleValueContainer().decode(String.self).lowercased()
        self = ItemType(rawValue: label) ?? .unknown
    }

}
