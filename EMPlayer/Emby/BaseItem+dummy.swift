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
    
    static var dummy: BaseItem = BaseItem(name: "ガンダム",
                                      originalTitle: nil,
                                      id: UUID().uuidString,
                                      sourceType: nil,
                                      hasSubtitle: nil,
                                      path: nil,
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
                                          path: nil,
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
        return BaseItem(name: "青春ブタ野郎はバニーガール先輩の夢を見ない",
                        originalTitle: nil,
                        id: UUID().uuidString,
                        sourceType: nil,
                        hasSubtitle: nil,
                        path: nil,
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
            
            let movieImages = [
                Bundle.main.url(forResource: "movie01", withExtension: "png")!,
                Bundle.main.url(forResource: "movie02", withExtension: "png")!,
                Bundle.main.url(forResource: "movie03", withExtension: "png")!,
            ]
            let previewImages = [
                Bundle.main.url(forResource: "preview01", withExtension: "png")!,
                Bundle.main.url(forResource: "preview02", withExtension: "png")!,
                Bundle.main.url(forResource: "preview03", withExtension: "png")!,
            ]
            
            switch self.type {
            case .movie:
                return movieImages.randomElement()!
            case .episode, .video, .boxSet, .folder, .collectionFolder:
                return previewImages.randomElement()!
            case .series:
                return movieImages.randomElement()!
            default:
                return nil
            }
        } else if let _ = imageTags?.primary, let server = server {
            return URL(string: "\(server)/Items/\(self.id)/Images/Primary")!
        }
        return nil
    }

}
