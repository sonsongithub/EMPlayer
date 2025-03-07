//
//  User.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/05.
//

import Foundation

// MARK: - User Structure
struct User: Codable {
    let name: String
    let serverId: String
    let prefix: String
    let dateCreated: String
    let id: String
    let hasPassword: Bool
    let hasConfiguredPassword: Bool
    let lastLoginDate: String
    let lastActivityDate: String
    let configuration: Configuration
    let policy: Policy
    let hasConfiguredEasyPassword: Bool

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case serverId = "ServerId"
        case prefix = "Prefix"
        case dateCreated = "DateCreated"
        case id = "Id"
        case hasPassword = "HasPassword"
        case hasConfiguredPassword = "HasConfiguredPassword"
        case lastLoginDate = "LastLoginDate"
        case lastActivityDate = "LastActivityDate"
        case configuration = "Configuration"
        case policy = "Policy"
        case hasConfiguredEasyPassword = "HasConfiguredEasyPassword"
    }
}

// MARK: - Configuration Structure
struct Configuration: Codable {
    let playDefaultAudioTrack: Bool
    let displayMissingEpisodes: Bool
    let subtitleMode: String
    let orderedViews: [String]
    let latestItemsExcludes: [String]
    let myMediaExcludes: [String]
    let hidePlayedInLatest: Bool
    let hidePlayedInMoreLikeThis: Bool
    let hidePlayedInSuggestions: Bool
    let rememberAudioSelections: Bool
    let rememberSubtitleSelections: Bool
    let enableNextEpisodeAutoPlay: Bool
    let resumeRewindSeconds: Int
    let introSkipMode: String
    let enableLocalPassword: Bool

    enum CodingKeys: String, CodingKey {
        case playDefaultAudioTrack = "PlayDefaultAudioTrack"
        case displayMissingEpisodes = "DisplayMissingEpisodes"
        case subtitleMode = "SubtitleMode"
        case orderedViews = "OrderedViews"
        case latestItemsExcludes = "LatestItemsExcludes"
        case myMediaExcludes = "MyMediaExcludes"
        case hidePlayedInLatest = "HidePlayedInLatest"
        case hidePlayedInMoreLikeThis = "HidePlayedInMoreLikeThis"
        case hidePlayedInSuggestions = "HidePlayedInSuggestions"
        case rememberAudioSelections = "RememberAudioSelections"
        case rememberSubtitleSelections = "RememberSubtitleSelections"
        case enableNextEpisodeAutoPlay = "EnableNextEpisodeAutoPlay"
        case resumeRewindSeconds = "ResumeRewindSeconds"
        case introSkipMode = "IntroSkipMode"
        case enableLocalPassword = "EnableLocalPassword"
    }
}


// MARK: - Policy Structure
struct Policy: Codable {
    let isAdministrator: Bool
    let isHidden: Bool
    let isHiddenRemotely: Bool
    let isHiddenFromUnusedDevices: Bool
    let isDisabled: Bool
    let lockedOutDate: Int
    let allowTagOrRating: Bool
    let blockedTags: [String]
    let isTagBlockingModeInclusive: Bool
    let includeTags: [String]
    let enableUserPreferenceAccess: Bool
    let enableRemoteControlOfOtherUsers: Bool
    let enableSharedDeviceControl: Bool
    let enableRemoteAccess: Bool
    let enableLiveTvManagement: Bool
    let enableLiveTvAccess: Bool
    let enableMediaPlayback: Bool
    let enableAudioPlaybackTranscoding: Bool
    let enableVideoPlaybackTranscoding: Bool
    let enablePlaybackRemuxing: Bool
    let enableContentDeletion: Bool
    let enableContentDownloading: Bool
    let enableSubtitleDownloading: Bool
    let enableSubtitleManagement: Bool
    let enableSyncTranscoding: Bool
    let enableMediaConversion: Bool
    let enableAllChannels: Bool
    let enableAllFolders: Bool
    let enablePublicSharing: Bool
    let authenticationProviderId: String
    let simultaneousStreamLimit: Int
    let enableAllDevices: Bool
    let allowCameraUpload: Bool
    let allowSharingPersonalItems: Bool

    enum CodingKeys: String, CodingKey {
        case isAdministrator = "IsAdministrator"
        case isHidden = "IsHidden"
        case isHiddenRemotely = "IsHiddenRemotely"
        case isHiddenFromUnusedDevices = "IsHiddenFromUnusedDevices"
        case isDisabled = "IsDisabled"
        case lockedOutDate = "LockedOutDate"
        case allowTagOrRating = "AllowTagOrRating"
        case blockedTags = "BlockedTags"
        case isTagBlockingModeInclusive = "IsTagBlockingModeInclusive"
        case includeTags = "IncludeTags"
        case enableUserPreferenceAccess = "EnableUserPreferenceAccess"
        case enableRemoteControlOfOtherUsers = "EnableRemoteControlOfOtherUsers"
        case enableSharedDeviceControl = "EnableSharedDeviceControl"
        case enableRemoteAccess = "EnableRemoteAccess"
        case enableLiveTvManagement = "EnableLiveTvManagement"
        case enableLiveTvAccess = "EnableLiveTvAccess"
        case enableMediaPlayback = "EnableMediaPlayback"
        case enableAudioPlaybackTranscoding = "EnableAudioPlaybackTranscoding"
        case enableVideoPlaybackTranscoding = "EnableVideoPlaybackTranscoding"
        case enablePlaybackRemuxing = "EnablePlaybackRemuxing"
        case enableContentDeletion = "EnableContentDeletion"
        case enableContentDownloading = "EnableContentDownloading"
        case enableSubtitleDownloading = "EnableSubtitleDownloading"
        case enableSubtitleManagement = "EnableSubtitleManagement"
        case enableSyncTranscoding = "EnableSyncTranscoding"
        case enableMediaConversion = "EnableMediaConversion"
        case enableAllChannels = "EnableAllChannels"
        case enableAllFolders = "EnableAllFolders"
        case enablePublicSharing = "EnablePublicSharing"
        case authenticationProviderId = "AuthenticationProviderId"
        case simultaneousStreamLimit = "SimultaneousStreamLimit"
        case enableAllDevices = "EnableAllDevices"
        case allowCameraUpload = "AllowCameraUpload"
        case allowSharingPersonalItems = "AllowSharingPersonalItems"
    }
}
