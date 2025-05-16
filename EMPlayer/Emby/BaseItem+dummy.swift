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
    
    func imageURL(server: String?) -> URL? {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
//            return URL(string: "https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcTSFIR8C4EqpjhnYLI070qP1J7vUVa7-c0aCKVRdj7bnoWpbiv50y1zwPepr7V-Z_LZNZRoYA")!
            return URL(string: "https://artworks.thetvdb.com/banners/episodes/76885/219124.jpg")!
//            return URL(string: "https://artworks.thetvdb.com/banners/v4/episode/9867241/screencap/64b1c790c0dd3.jpg")!
        } else if let _ = imageTags?.primary, let server = server {
            return URL(string: "\(server)/Items/\(self.id)/Images/Primary")!
        }
        return nil
    }

}
