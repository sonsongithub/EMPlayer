//
//  BaseItem.swift
//  Emby Player
//
//  Created by sonson on 2025/03/09.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation
import SwiftUI

struct BaseItem: Codable, Equatable {
    static func == (lhs: BaseItem, rhs: BaseItem) -> Bool {
        lhs.id == rhs.id
    }
    
    let name: String
    let originalTitle: String?
    let id: String
    let sourceType: String?
    let hasSubtitle: Bool?
    let path: String?
    let overview: String?
    let aspectRatio: String?
    let isHD: Bool?
    let seriesId: String?
    let seriesName: String?
    let seasonName: String?
    let width: Int?
    let height: Int?
    let mediaSource: [MediaSource]?
    let mediaStreams: [MediaStream]?
    let indexNumber: Int?
    let isFolder: Bool?
    let type: ItemType
    let collectionType: CollectionType?
    let runtimeTicks: Int?

    let userData: UserData?
    
    let imageTags: ImageTags?
    
    init(name: String,
         originalTitle: String? = nil,
         id: String,
         sourceType: String? = nil,
         hasSubtitle: Bool? = nil,
         path: String? = nil,
         overview: String? = nil,
         aspectRatio: String? = nil,
         isHD: Bool? = nil,
         seriesId: String? = nil,
         seriesName: String? = nil,
         seasonName: String? = nil,
         width: Int? = nil,
         height: Int? = nil,
         mediaSource: [MediaSource]? = nil,
         mediaStreams: [MediaStream]? = nil,
         indexNumber: Int? = nil,
         isFolder: Bool? = nil,
         type: ItemType? = nil,
         userData: UserData? = nil,
         imageTags: ImageTags? = nil,
         collectionType: CollectionType? = nil,
         runtimeTicks: Int? = nil) {
        self.name = name
        self.originalTitle = originalTitle
        self.id = id
        self.sourceType = sourceType
        self.hasSubtitle = hasSubtitle
        self.path = path
        self.overview = overview
        self.aspectRatio = aspectRatio
        self.isHD = isHD
        self.seriesId = seriesId
        self.seriesName = seriesName
        self.seasonName = seasonName
        self.width = width
        self.height = height
        self.mediaStreams = mediaStreams
        self.mediaSource = mediaSource
        self.indexNumber = indexNumber
        self.isFolder = isFolder
        self.runtimeTicks = runtimeTicks
        if let type = type {
            self.type = type
        } else {
            self.type = .unknown
        }
        self.userData = userData
        self.imageTags = imageTags
        self.collectionType = collectionType
    }

    init(item: PlayableItem) {
        let userData = item.userData ?? UserData(key: "Key",
                                                 unplayedItemCount: nil,
                                                 playbackPositionTicks: 0,
                                                 playCount: 0,
                                                 isFavorite: false,
                                                 played: false)
        self.init(name: item.name,
                  originalTitle: nil,
                  id: item.id,
                  sourceType: item.sourceType,
                  hasSubtitle: item.hasSubtitle,
                  path: item.path,
                  overview: item.overview,
                  aspectRatio: nil,
                  isHD: nil,
                  seriesId: nil,
                  seriesName: item.seriesName,
                  seasonName: item.seasonName,
                  width: nil,
                  height: nil,
                  mediaSource: item.mediaSources,
                  mediaStreams: item.mediaStreams,
                  indexNumber: item.indexNumber,
                  isFolder: false,
                  type: item.type,
                  userData: userData,
                  imageTags: item.imageTags,
                  collectionType: nil,
                  runtimeTicks: nil
        )
    }

    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case originalTitle  = "OriginalTitle"
        case id             = "Id"
        case sourceType     = "SourceType"
        case hasSubtitle    = "HasSubtitle"
        case path           = "Path"
        case overview       = "Overview"
        case aspectRatio    = "AspectRatio"
        case isHD           = "IsHD"
        case seriesId       = "SeriesId"
        case seriesName     = "SeriesName"
        case seasonName     = "SeasonName"
        case width          = "Width"
        case height         = "Height"
        case mediaSource    = "MediaSources"
        case indexNumber    = "IndexNumber"
        case isFolder       = "IsFolder"
        case type           = "Type"
        case mediaStreams   = "MediaStreams"
        case userData       = "UserData"
        case imageTags      = "ImageTags"
        case collectionType = "CollectionType"
        case runtimeTicks   = "RunTimeTicks"
    }

//    func session(positionTicks: Int? = nil) -> PlaybackStart {
//        return PlaybackStart(queueableMediaTypes: [.video],
//                              canSeek: true,
//                              items: [],
//                              itemId: id,
//                              mediaSourceId: mediaSource?.first?.id ?? "",
//                              audioStreamIndex: nil,
//                              subtitleStreamIndex: nil,
//                              isPaused: false,
//                              isMuted: false,
//                              positionTicks: positionTicks ?? userData.playbackPositionTicks,
//                              volumeLevel: nil,
//                              playMethode: .directPlay,
//                              liveStreamId: "LiveStreamId",
//                              playSessionId: "PlaySessionId")
//    }

//    func imageUrl(with type: ImageType) -> URL? {
//        return URL(string: "http://server753.seedhost.eu:8096/emby/Items/\(id)/Images/\(type.rawValue)")
//    }

    func playableVideo(from server: String) -> URL? {
        guard let mediaSource = mediaSource?.first else { return nil }
//        let baseUrl = server.baseUrl
        
        guard let baseUrl = URL(string: server) else { return nil }

        if mediaSource.supportsDirectStream {

            let urlPath = baseUrl.appendingPathComponent("/Videos/\(id)/stream.\(mediaSource.container)")
            guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else { return nil }
            urlComponents.queryItems = [
                URLQueryItem(name: "Static", value: "true"),
                URLQueryItem(name: "mediaSourceId", value: mediaSource.id),
                URLQueryItem(name: "deviceId", value: "xxxx")
            ]
            guard let url = urlComponents.url else { return nil }
//            return Video(url: url)
            return url
        } else if mediaSource.supportsDirectPlay {

            let urlPath = baseUrl.appendingPathComponent("/Videos/\(id)/main.m3u8")
            guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else { return nil }
            urlComponents.queryItems = [
                //                URLQueryItem(name: "PlaySessionId", value: ""),
                URLQueryItem(name: "MediaSourceId", value: mediaSource.id),
                URLQueryItem(name: "DeviceId", value: "xxxx")

            ]
            guard let url = urlComponents.url else { return nil }
            return url
//            return Video(url: url)

        } else {
            print("Item du not support Direct Stream")
            return nil
        }
    }
}
