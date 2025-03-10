//
//  ExternalLinks.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

struct ExternalLinks: Codable {

    let name: String
    let url: URL

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case url = "Url"
    }
}

