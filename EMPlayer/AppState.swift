//
//  AppState.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

class AppState: ObservableObject {
    
    // Caution, this is not a safety code.
    // token should be stored in Keychain.
    
    var ready: Bool {
        return server != nil && token != nil && userID != nil
    }

    @Published var server: String?
    @Published var token: String?
    @Published var userID: String?

    init() {
        loadFromUserDefaults()
    }

    public func saveToUserDefaults() {
        print(#function)
        UserDefaults.standard.set(server, forKey: "server")
        UserDefaults.standard.set(token, forKey: "token")
        UserDefaults.standard.set(userID, forKey: "userID")
        UserDefaults.standard.synchronize()
    }

    private func loadFromUserDefaults() {
        if let savedServer = UserDefaults.standard.string(forKey: "server"), server == nil {
            server = savedServer
        }
        if let savedToken = UserDefaults.standard.string(forKey: "token"), token == nil {
            token = savedToken
        }
        if let savedUserID = UserDefaults.standard.string(forKey: "userID"), userID == nil {
            userID = savedUserID
        }
    }

    func logout() {
        server = nil
        token = nil
        userID = nil
        UserDefaults.standard.removeObject(forKey: "server")
        UserDefaults.standard.removeObject(forKey: "token")
        UserDefaults.standard.removeObject(forKey: "userID")
    }
}
