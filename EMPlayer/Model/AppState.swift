//
//  AppState.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//
import SwiftUI

enum AppStateError: Error {
    case notReady
}

protocol AuthProviding: AnyObject {
    var server: String?  { get }
    var token:  String?  { get }
    var userID: String?  { get }
}

class AppState: ObservableObject, AuthProviding {

    // MARK: - Keys
    private enum Keys {
        static let server = "server"
        static let token  = "token"
        static let userID = "userID"
        static let playerVolume = "playerVolume"
    }

    // 認証まわり
    var ready: Bool { server != nil && token != nil && userID != nil }

    @Published var server: String?
    @Published var token: String?
    @Published var userID: String?
    @Published var isAuthenticated: Bool = false

    // アプリ状態
    @Published var selectedItem: BaseItem? = nil
    @Published var searchQuery: String? = nil
    @Published var playingItem: ItemNode? = nil
    @Published var selectedTab: Int = 0

    // 再生系の永続設定（追加）
    @Published var playerVolume: Float = 0.5 {
        didSet {
            // 0.0〜1.0 に正規化してから保存
            let clamped = max(0.0, min(1.0, playerVolume))
            if clamped != playerVolume { playerVolume = clamped; return }
            UserDefaults.standard.set(clamped, forKey: Keys.playerVolume)
        }
    }

    // MARK: - Init
    init() {
        loadFromUserDefaults()
    }

    init(server: String, token: String, userID: String, isAuthenticated: Bool) {
        self.server = server
        self.token = token
        self.userID = userID
        self.isAuthenticated = isAuthenticated
        loadFromUserDefaults() // 音量などを読む
    }

    // MARK: - Auth
    func get() throws -> (String, String, String) {
        guard let server, let token, let userID else { throw AppStateError.notReady }
        return (server, token, userID)
    }

    // MARK: - Persist
    public func saveToUserDefaults() {
        UserDefaults.standard.set(server, forKey: Keys.server)
        UserDefaults.standard.set(token,  forKey: Keys.token)
        UserDefaults.standard.set(userID, forKey: Keys.userID)
        // playerVolume は didSet で都度保存されるのでここでは不要
        UserDefaults.standard.synchronize()
    }

    private func loadFromUserDefaults() {
        // 認証情報
        if let savedServer = UserDefaults.standard.string(forKey: Keys.server), server == nil {
            server = savedServer
        }
        if let savedToken = UserDefaults.standard.string(forKey: Keys.token), token == nil {
            token = savedToken
        }
        if let savedUserID = UserDefaults.standard.string(forKey: Keys.userID), userID == nil {
            userID = savedUserID
        }
        if server != nil && token != nil && userID != nil {
            isAuthenticated = true
        }

        // 音量（Float として保存・読込。Double 保存でも吸収）
        if let f = UserDefaults.standard.object(forKey: Keys.playerVolume) as? Float {
            playerVolume = max(0.0, min(1.0, f))
        } else if let d = UserDefaults.standard.object(forKey: Keys.playerVolume) as? Double {
            playerVolume = max(0.0, min(1.0, Float(d)))
        } // なければデフォルト 0.5 のまま
    }

    func logout() {
        server = nil
        token  = nil
        userID = nil
        UserDefaults.standard.removeObject(forKey: Keys.server)
        UserDefaults.standard.removeObject(forKey: Keys.token)
        UserDefaults.standard.removeObject(forKey: Keys.userID)
        // 音量はユーザ設定として残したいなら消さない。
        // 完全リセットしたいなら以下を有効化:
        // UserDefaults.standard.removeObject(forKey: Keys.playerVolume)
    }
}
