//
//  SessionInfo.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/05.
//

import Foundation

// MARK: - SessionInfo Structure
struct SessionInfo: Codable {
    let playState: PlayState
    let additionalUsers: [String]
    let remoteEndPoint: String
    let protocolType: String
    let playlistIndex: Int
    let playlistLength: Int
    let id: String
    let serverId: String
    let userId: String
    let userName: String
    let client: String
    let lastActivityDate: String
    let deviceName: String
    let internalDeviceId: Int
    let deviceId: String
    let applicationVersion: String
    let supportedCommands: [String]
    let supportsRemoteControl: Bool

    enum CodingKeys: String, CodingKey {
        case playState = "PlayState"
        case additionalUsers = "AdditionalUsers"
        case remoteEndPoint = "RemoteEndPoint"
        case protocolType = "Protocol"
        case playlistIndex = "PlaylistIndex"
        case playlistLength = "PlaylistLength"
        case id = "Id"
        case serverId = "ServerId"
        case userId = "UserId"
        case userName = "UserName"
        case client = "Client"
        case lastActivityDate = "LastActivityDate"
        case deviceName = "DeviceName"
        case internalDeviceId = "InternalDeviceId"
        case deviceId = "DeviceId"
        case applicationVersion = "ApplicationVersion"
        case supportedCommands = "SupportedCommands"
        case supportsRemoteControl = "SupportsRemoteControl"
    }
}

// MARK: - PlayState Structure
struct PlayState: Codable {
    let canSeek: Bool
    let isPaused: Bool
    let isMuted: Bool
    let repeatMode: String
    let subtitleOffset: Int
    let shuffle: Bool
    let playbackRate: Int

    enum CodingKeys: String, CodingKey {
        case canSeek = "CanSeek"
        case isPaused = "IsPaused"
        case isMuted = "IsMuted"
        case repeatMode = "RepeatMode"
        case subtitleOffset = "SubtitleOffset"
        case shuffle = "Shuffle"
        case playbackRate = "PlaybackRate"
    }
}
