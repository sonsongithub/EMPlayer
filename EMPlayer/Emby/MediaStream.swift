//
//  MediaStream.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

struct MediaStream: Codable {
    let displayTitle: String?
    let bitRate: Int?
    let aspectRatio: String?
    let profile: String?
    let type: String
    let index: Int?
    let codec: String

    enum CodingKeys: String, CodingKey {
        case displayTitle   = "DisplayTitle"
        case bitRate        = "BitRate"
        case aspectRatio    = "AspectRatio"
        case profile        = "Profile"
        case type           = "Type"
        case index          = "Index"
        case codec          = "Codec"
    }
}

