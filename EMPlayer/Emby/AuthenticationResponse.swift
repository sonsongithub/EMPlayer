//
//  AuthenticationResponse.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/05.
//

import Foundation

// MARK: - Root Structure
struct AuthenticationResponse: Codable {
    let user: User
    let sessionInfo: SessionInfo
    let accessToken: String
    let serverId: String

    enum CodingKeys: String, CodingKey {
        case user = "User"
        case sessionInfo = "SessionInfo"
        case accessToken = "AccessToken"
        case serverId = "ServerId"
    }
}

