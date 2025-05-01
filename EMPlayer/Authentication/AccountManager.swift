//
//  AccountManager.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/07.
//

import SwiftUI
import KeychainAccess

typealias AccountKey = String

@MainActor
class AccountManager: ObservableObject {
    private let keychain = Keychain(service: "com.sonson.EMPlayer")

    // 読み込んだアカウントリストを @Published で公開
    @Published var accounts: [AccountKey: Account] = [:]
    @Published var names: [String] = []

    init() {
        print("\(type(of: self)) \(#function)")
        loadAccounts()  
    }
    
    deinit {
        print("\(type(of: self)) \(#function)")
    }
    
    func displayName(for key: AccountKey) -> String {
        guard let account = accounts[key] else {
            return ""
        }
        return "\(account.username)@\(account.server)"
    }

    func saveAccount(_ account: Account) {
        let key = "\(account.server)|\(account.username)"
        if let data = try? JSONEncoder().encode(account) {
            keychain[data: key] = data
        }
        loadAccounts() // データを保存したら再読み込み
    }

    func loadAccounts() {
        var newAccounts: [AccountKey: Account] = [:]
        for key in (try? keychain.allKeys()) ?? [] {
            if let data = keychain[data: key] {
                do {
                    let account = try JSONDecoder().decode(Account.self, from: data)
                    newAccounts[key] = account
                } catch {
                    print("Failed to decode account data for key \(key): \(error)")
                }
            }
        }
        self.accounts = newAccounts
        self.names = newAccounts.values.map { "\($0.server)|\($0.username)" }
    }

    func deleteAccount(server: String, username: String) {
        let key = "\(server)|\(username)"
        try? keychain.remove(key)
        loadAccounts() // 削除後に再読み込み
    }
    
    func deleteAll() {
        for key in (try? keychain.allKeys()) ?? [] {
            try? keychain.remove(key)
        }
        loadAccounts()
    }
}
