//
//  QueryResult.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/10.
//
//  Created by Mats Mollestad on 26/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//
// Original is here, https://github.com/MatsMoll/Emby-Player-iOS

import Foundation

struct QueryResult<T: Codable>: Codable {
    let items: [T]
    let totalRecordCount: Int

    enum CodingKeys: String, CodingKey {
        case items              = "Items"
        case totalRecordCount   = "TotalRecordCount"
    }
}
