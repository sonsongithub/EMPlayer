//
//  PlayableEpisode.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

struct PlayableEpisode: Codable {
    let name: String
    let id: String
    let sourceType: String?
    let hasSubtitle: Bool?
    let path: String?
    let overview: String?
    var seasonTitleText: String? {
        guard let seriesName = seriesName, let seasonName = seasonName else { return nil }
        return seriesName + ", " + seasonName
    }
    var episodeText: String? {
        guard let indexNumber = indexNumber else { return "" }
        return "Episode \(indexNumber)" + (seasonName != nil ? ", \(seasonName!)" : "")
    }
    let type: String

    let indexNumber: Int?
    let seriesId: String?
    let seriesName: String?
    let seasonName: String?

    let userData: UserData?
    let imageTags: ImageTags?

    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case id             = "Id"
        case sourceType     = "SourceType"
        case hasSubtitle    = "HasSubtitles"
        case path           = "Path"
        case overview       = "Overview"
        case seriesId       = "SeriesId"
        case seriesName     = "SeriesName"
        case seasonName     = "SeasonName"
        case indexNumber    = "IndexNumber"
        case type           = "Type"
        case userData       = "UserData"
        case imageTags  = "ImageTags"
    }

//    func imageUrl(with type: ImageType) -> URL? {
//        return URL(string: "http://server753.seedhost.eu:8096/emby/Items/\(id)/Images/\(type.rawValue)")
//    }
}
