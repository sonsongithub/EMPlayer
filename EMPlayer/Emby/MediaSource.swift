//
//  MediaSource.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

struct MediaSource: Codable {
    let id: String
    let container: String
    let name: String
    let path: String
    let liveStreamId: String?
    let supportsDirectPlay: Bool
    let supportsDirectStream: Bool
    let supportsTranscoding: Bool
    let tag: String?

    enum CodingKeys: String, CodingKey {
        case id                     = "Id"
        case container              = "Container"
        case name                   = "Name"
        case path                   = "Path"
        case liveStreamId           = "LiveStreamId"
        case supportsDirectPlay     = "SupportsDirectPlay"
        case supportsDirectStream   = "SupportsDirectStream"
        case supportsTranscoding    = "SupportsTranscoding"
        case tag                    = "Etag"
    }
}

