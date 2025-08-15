//
//  PlayableIteming.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

protocol PlayableIteming: Codable {

    var name: String { get }
    var id: String { get }
    var sourceType: String? { get }
    var hasSubtitle: Bool? { get }
    var path: String? { get }
    var overview: String? { get }
    var seasonTitleText: String? { get }
    var mediaSources: [MediaSource] { get }
    var mediaStreams: [MediaStream] { get }
    var type: ItemType { get }
    var userData: UserData? { get }
    var runTime: Int { get }
    var externalLinks: [ExternalLinks]? { get }
    var communityRating: Double? { get }

    var diskUrlPath: String? { get }
    
    var imageTags: ImageTags? { get }

//    func imageUrl(with type: ImageType) -> URL?
//    func playableVideo(in player: SupportedContainerController, from server: EmbyAPI) -> Video?
}

struct PlayableMovie: PlayableIteming {
    let userData: UserData?
    let id: String
    var hasSubtitle: Bool?
    var aspectRatio: String
    var width: Int
    var height: Int
    var mediaSources: [MediaSource]
    var mediaStreams: [MediaStream]
    var type: ItemType
    let name: String
    let originalTitle: String?
    let sourceType: String?
    let path: String?
    let overview: String?
    let isHD: Bool?
    let seasonTitleText: String? = nil
    var diskUrlPath: String?
    let runTime: Int
    let externalLinks: [ExternalLinks]?
    let communityRating: Double?
    let imageTags: ImageTags?

    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case originalTitle  = "OriginalTitle"
        case id             = "Id"
        case sourceType     = "SourceType"
        case hasSubtitle    = "HasSubtitles"
        case path           = "Path"
        case overview       = "Overview"
        case aspectRatio    = "AspectRatio"
        case isHD           = "IsHD"
        case width          = "Width"
        case height         = "Height"
        case mediaSources   = "MediaSources"
        case type           = "Type"
        case mediaStreams   = "MediaStreams"
        case userData       = "UserData"
        case diskUrlPath    = "DiskUrlPath"
        case runTime        = "RunTimeTicks"
        case externalLinks  = "ExternalLinks"
        case communityRating = "CommunityRating"
        case imageTags  = "ImageTags"
    }
}


struct PlayableItem: PlayableIteming, Hashable {

    static func == (lhs: PlayableItem, rhs: PlayableItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let name: String
    let id: String
    let sourceType: String?
    let hasSubtitle: Bool?
    let path: String?
    let overview: String?
    let seasonName: String?
    let seriesName: String?
    let indexNumber: Int?
    var seasonTitleText: String? { return seasonName }
    let mediaSources: [MediaSource]
    let mediaStreams: [MediaStream]
    let type: ItemType
    let userData: UserData?
    let runTime: Int
    let genres: [String]?
    let externalLinks: [ExternalLinks]?
    let communityRating: Double?
    
    let imageTags: ImageTags?

    /// Used to store the url for an item that is saved offline
    var diskUrlPath: String?

    enum CodingKeys: String, CodingKey {
        case name           = "Name"
        case id             = "Id"
        case sourceType     = "SourceType"
        case hasSubtitle    = "HasSubtitles"
        case path           = "Path"
        case overview       = "Overview"
        case seriesName     = "SeriesName"
        case seasonName     = "SeasonName"
        case indexNumber    = "IndexNumber"
        case mediaSources   = "MediaSources"
        case mediaStreams   = "MediaStreams"
        case type           = "Type"
        case userData       = "UserData"
        case diskUrlPath    = "DiskUrlPath"
        case runTime        = "RunTimeTicks"
        case genres         = "Genres"
        case externalLinks  = "ExternalUrls"
        case communityRating = "CommunityRating"
        case imageTags  = "ImageTags"
    }
}

struct SyncItem: PlayableIteming, Hashable {

    static func == (lhs: SyncItem, rhs: SyncItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var name: String { itemName }
    let itemName: String
    var id: String { String(idAsNumber) }
    let idAsNumber: Int
    let itemId: Int
    let jobId: Int
    let sourceType: String?
    let hasSubtitle: Bool?
    let path: String?
    let overview: String?
    let seasonName: String?
    let seriesName: String?
    let indexNumber: Int?
    var seasonTitleText: String? { return seasonName }
    var mediaSources: [MediaSource] { [] }
    let mediaSource: SyncMediaSource?
    var mediaStreams: [MediaStream] { mediaSource?.mediaStreams ?? [] }
    var type: ItemType { .movie }
    let userData: UserData?
    var runTime: Int { 0 }
    let genres: [String]?
    let externalLinks: [ExternalLinks]?
    let communityRating: Double?
    let imageTags: ImageTags?

    /// Used to store the url for an item that is saved offline
    var diskUrlPath: String?

    enum CodingKeys: String, CodingKey {
        case itemName       = "ItemName"
        case idAsNumber     = "Id"
        case itemId         = "ItemId"
        case jobId          = "JobId"
        case sourceType     = "SourceType"
        case hasSubtitle    = "HasSubtitles"
        case path           = "Path"
        case overview       = "Overview"
        case seriesName     = "SeriesName"
        case seasonName     = "SeasonName"
        case indexNumber    = "IndexNumber"
        case mediaSource    = "MediaSource"
        case userData       = "UserData"
        case diskUrlPath    = "DiskUrlPath"
        case genres         = "Genres"
        case externalLinks  = "ExternalUrls"
        case communityRating = "CommunityRating"
        case imageTags  = "ImageTags"
    }

    var playableItem: PlayableItem {
        PlayableItem(name: name,
                     id: id,
                     sourceType: sourceType,
                     hasSubtitle: hasSubtitle,
                     path: path,
                     overview: overview,
                     seasonName: seasonName,
                     seriesName: seriesName,
                     indexNumber: indexNumber,
                     mediaSources: mediaSources,
                     mediaStreams: mediaStreams,
                     type: .unknown,
                     userData: userData,
                     runTime: 0,
                     genres: genres,
                     externalLinks: externalLinks,
                     communityRating: communityRating, imageTags: imageTags,
                     diskUrlPath: diskUrlPath)
    }
}

extension PlayableIteming {

//    func imageUrl(with type: ImageType) -> URL? {
//        return URL(string: "http://server753.seedhost.eu:8096/emby/Items/\(id)/Images/\(type.rawValue)")
//    }

//    func playableVideo(in player: SupportedContainerController, from server: EmbyAPI) -> Video? {
//
//        guard var mediaSource = mediaSources.first else { return nil }
//        if let perferedMediaSource = self.mediaSources.first(where: { player.supports(container: $0.container) }) {
//            mediaSource = perferedMediaSource
//        }
//        guard let videoStream = mediaStreams.filter({ $0.type == "Video" }).first else { return nil }
//        guard let audioStream = mediaStreams.filter({ $0.type == "Audio" }).first else { return nil }
//
//        let baseUrl = server.baseUrl
//
//        var urlPathString = "emby/Videos/\(id)/"
//
//        if player.supports(container: mediaSource.container),
//            videoStream.codec != "mpeg4" {  // AVPlayerLayer do not play mpeg4
//
//            urlPathString += "stream.\(mediaSource.container)"
//            let urlPath = baseUrl.appendingPathComponent(urlPathString)
//            guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else { return nil }
//            urlComponents.queryItems = [
//                URLQueryItem(name: "Static", value: "true"),
//                URLQueryItem(name: "mediaSourceId", value: mediaSource.id),
//                URLQueryItem(name: "deviceId", value: UIDevice.current.identifierForVendor?.uuidString ?? "xxxx"),
//                URLQueryItem(name: "AudioCodec", value: audioStream.codec),
//                URLQueryItem(name: "VideoCodec", value: videoStream.codec)
//            ]
//            guard let url = urlComponents.url else { return nil }
//            return Video(url: url)
//        } else {
//            urlPathString += "main.m3u8"
//            let urlPath = baseUrl.appendingPathComponent(urlPathString)
//            guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else { return nil }
//            urlComponents.queryItems = [
//                URLQueryItem(name: "MediaSourceId", value: mediaSource.id),
//                URLQueryItem(name: "DeviceId", value: UIDevice.current.identifierForVendor?.uuidString ?? "xxxx"),
//                URLQueryItem(name: "AudioCodec", value: "mp3"),
//                URLQueryItem(name: "VideoCodec", value: "h264")
//            ]
//            guard let url = urlComponents.url else { return nil }
//            return Video(url: url)
//
//        }
//
//    }
}
