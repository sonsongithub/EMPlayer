//
//  BaseItem.swift
//  Emby Player
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import UIKit

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

struct QueryResult<T: Codable>: Codable {
    let items: [T]
    let totalRecordCount: Int

    enum CodingKeys: String, CodingKey {
        case items              = "Items"
        case totalRecordCount   = "TotalRecordCount"
    }
}

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

struct ImageTags: Codable {
    let primary: String?
    let art: String?
    let backdrop: String?
    let banner: String?
    let logo: String?
    let thumb: String?
    let disc: String?
    let box: String?
    let screenshot: String?
    let menu: String?
    let chapter: String?
    
    enum CodingKeys: String, CodingKey {
        case primary    = "Primary"
        case art        = "Art"
        case backdrop   = "Backdrop"
        case banner     = "Banner"
        case logo       = "Logo"
        case thumb      = "Thumb"
        case disc       = "Disc"
        case box        = "Box"
        case screenshot = "Screenshot"
        case menu       = "Menu"
        case chapter    = "Chapter"
    }
    
    func imageURL(server: String, id: String) -> URL? {
        return URL(string: "\(server)/Items/\(id)/Images/Primary")
    }
}

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

struct ExternalLinks: Codable {

    let name: String
    let url: URL

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case url = "Url"
    }
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

struct BaseItem: Codable {
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

    let userData: UserData?
    
    let imageTags: ImageTags?
    
    init(name: String, originalTitle: String?, id: String, sourceType: String?, hasSubtitle: Bool?, path: String?, overview: String?, aspectRatio: String?, isHD: Bool?, seriesId: String?, seriesName: String?, seasonName: String?, width: Int?, height: Int?, mediaSource: [MediaSource]?, mediaStreams: [MediaStream]?, indexNumber: Int?, isFolder: Bool?, type: ItemType?, userData: UserData?, imageTags: ImageTags?, collectionType: CollectionType?) {
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
                  collectionType: nil
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
        case  collectionType = "CollectionType"
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
