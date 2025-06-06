//
//  BaseItem+dummy.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/09.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

extension BaseItem {
    static func createDummyURLforPath(type: ItemType) -> String? {
        
        let movieImages = [
            Bundle.main.url(forResource: "movie01", withExtension: "png"),
            Bundle.main.url(forResource: "movie02", withExtension: "png"),
            Bundle.main.url(forResource: "movie03", withExtension: "png"),
            nil
        ]
        let previewImages = [
            Bundle.main.url(forResource: "preview01", withExtension: "png"),
            Bundle.main.url(forResource: "preview02", withExtension: "png"),
            Bundle.main.url(forResource: "preview03", withExtension: "png"),
            nil
        ]
        
        let url: URL? = {
            switch type {
            case .movie:
                return movieImages.randomElement()!
            case .episode, .video, .boxSet, .folder, .collectionFolder:
                return previewImages.randomElement()!
            case .series:
                return movieImages.randomElement()!
            default:
                return nil
            }
        }()
        
        guard let url = url else {
            return nil
        }
        
        return url.absoluteString
    }
    static var dummy: BaseItem = BaseItem(name: "ガンダム",
                                      originalTitle: nil,
                                      id: UUID().uuidString,
                                      sourceType: nil,
                                      hasSubtitle: nil,
                                      path: createDummyURLforPath(type: .movie),
                                      overview: "to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. ",
                                      aspectRatio: nil,
                                      isHD: nil,
                                      seriesId: nil,
                                      seriesName: nil,
                                      seasonName: nil,
                                      width: nil,
                                      height: nil,
                                      mediaSource: nil,
                                      mediaStreams: nil,
                                      indexNumber: nil,
                                      isFolder: nil,
                                      type: nil,
                                      userData: nil,
                                      imageTags: nil,
                                      collectionType: nil)
    
    static func generateRandomItem() -> BaseItem {
        return BaseItem(name: "ガンダム",
                        originalTitle: nil,
                        id: UUID().uuidString,
                        sourceType: nil,
                        hasSubtitle: nil,
                        path: createDummyURLforPath(type: .movie),
                        overview: "to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. ",
                        aspectRatio: nil,
                        isHD: nil,
                        seriesId: nil,
                        seriesName: nil,
                        seasonName: nil,
                        width: nil,
                        height: nil,
                        mediaSource: nil,
                        mediaStreams: nil,
                        indexNumber: 1,
                        isFolder: nil,
                        type: nil,
                        userData: nil,
                        imageTags: nil,
                        collectionType: nil)
    }
    static func generateRandomItem(type: ItemType) -> BaseItem {
        let dummyPath = createDummyURLforPath(type: type)
        return BaseItem(name: "青春ブタ野郎はバニーガール先輩の夢を見ない",
                        originalTitle: nil,
                        id: UUID().uuidString,
                        sourceType: nil,
                        hasSubtitle: nil,
                        path: dummyPath,
                        overview: "to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. ",
                        aspectRatio: nil,
                        isHD: nil,
                        seriesId: nil,
                        seriesName: nil,
                        seasonName: nil,
                        width: nil,
                        height: nil,
                        mediaSource: nil,
                        mediaStreams: nil,
                        indexNumber: 1,
                        isFolder: nil,
                        type: type,
                        userData: nil,
                        imageTags: nil,
                        collectionType: nil)
    }
                                          
    func imageURL(server: String?) -> URL? {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            if let path = self.path, let url = URL(string: path) {
                return url
            }
        } else if let _ = imageTags?.primary, let server = server {
            return URL(string: "\(server)/Items/\(self.id)/Images/Primary")!
        }
        return nil
    }
    
    // create series data
    static func createSeriesData() -> BaseItem {
        return BaseItem(name: "機動戦士ガンダム",
                        originalTitle: nil,
                        id: UUID().uuidString,
                        sourceType: nil,
                        hasSubtitle: nil,
                        path: createDummyURLforPath(type: .series),
                        overview: "to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. ",
                        aspectRatio: nil,
                        isHD: nil,
                        seriesId: UUID().uuidString,
                        seriesName: "機動戦士ガンダム",
                        seasonName: "",
                        width: nil,
                        height: nil,
                        mediaSource: nil,
                        mediaStreams: nil,
                        indexNumber: 1,
                        isFolder: nil,
                        type: .series,
                        userData: nil,
                        imageTags: nil,
                        collectionType: nil)
    }
    
    // create season data
    static func createSeasonData(series: BaseItem) -> [BaseItem] {
        return [BaseItem(name: "機動戦士ガンダム 第1シーズン",
                        originalTitle: nil,
                        id: UUID().uuidString,
                        sourceType: nil,
                        hasSubtitle: nil,
                        path: createDummyURLforPath(type: .season),
                        overview: "to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. ",
                        aspectRatio: nil,
                        isHD: nil,
                        seriesId: series.id,
                        seriesName: series.name,
                        seasonName: "第1シーズン",
                        width: nil,
                        height: nil,
                        mediaSource: nil,
                        mediaStreams: nil,
                        indexNumber: 1,
                        isFolder: nil,
                        type: .season,
                        userData: nil,
                        imageTags: nil,
                        collectionType: nil),
                BaseItem(name: "機動戦士ガンダム 第2シーズン",
                                originalTitle: nil,
                                id: UUID().uuidString,
                                sourceType: nil,
                                hasSubtitle: nil,
                                path: createDummyURLforPath(type: .season),
                                overview: "to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. ",
                                aspectRatio: nil,
                                isHD: nil,
                                seriesId: series.id,
                                seriesName: series.name,
                                seasonName: "第2シーズン",
                                width: nil,
                                height: nil,
                                mediaSource: nil,
                                mediaStreams: nil,
                                indexNumber: 2,
                                isFolder: nil,
                                type: .season,
                                userData: nil,
                                imageTags: nil,
                                collectionType: nil)
                ]
    }
    
    // create episode data
    static func createEpisodeData(season: BaseItem) -> [BaseItem] {
        return (1...12).map { index in
            BaseItem(name: "機動戦士ガンダム 第\(String(describing: index))話",
                     originalTitle: nil,
                     id: UUID().uuidString,
                     sourceType: nil,
                     hasSubtitle: nil,
                     path: createDummyURLforPath(type: .episode),
                     overview: "to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. ",
                     aspectRatio: nil,
                     isHD: nil,
                     seriesId: season.seriesId,
                     seriesName: season.seriesName,
                     seasonName: season.name,
                     width: nil,
                     height: nil,
                     mediaSource: nil,
                     mediaStreams: nil,
                     indexNumber: index,
                     isFolder: nil,
                     type: .episode,
                     userData: nil,
                     imageTags: nil,
                     collectionType: nil)
        }
    }
}
