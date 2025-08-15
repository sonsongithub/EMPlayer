//
//  SyncMediaSource.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

struct SyncMediaSource: Codable {
    let container: String
    let path: String
    let mediaStreams: [MediaStream]

    enum CodingKeys: String, CodingKey {
        case container              = "Container"
        case path                   = "Path"
        case mediaStreams           = "MediaStreams"
    }
}
