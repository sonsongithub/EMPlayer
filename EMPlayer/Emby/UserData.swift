//
//  UserData.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

struct UserData: Codable {
    let key: String?
    let unplayedItemCount: Int?
    let playbackPositionTicks: Int?
    let playCount: Int?
    let isFavorite: Bool?
    let played: Bool?

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case unplayedItemCount = "UnplayedItemCount"
        case playbackPositionTicks = "PlaybackPositionTicks"
        case playCount = "PlayCount"
        case isFavorite = "IsFavorite"
        case played = "Played"
    }
}
