//
//  Account.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

import SwiftUI
import SwiftUI
import KeychainAccess

struct Account: Codable {
    let serverAddress: String
    let username: String
    let userID: String
    var token: String
}
