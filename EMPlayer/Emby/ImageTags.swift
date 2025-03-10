//
//  ImageTags.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

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

