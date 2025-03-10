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
                                      overview: "to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. ",
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
        if let _ = imageTags?.primary, let server = server {
            return URL(string: "\(server)/Items/\(self.id)/Images/Primary")!
        }
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return URL(string: "https://media.themoviedb.org/t/p/w600_and_h900_bestv2/11XJ0CUYn06Mht3qeGKJfVuWnYP.jpg")!
        }
        return nil
    }

}
