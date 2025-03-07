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

typealias AccountKey = String

class AccountManager: ObservableObject {
    private let keychain = Keychain(service: "com.sonson.EMPlayer")

    // 読み込んだアカウントリストを @Published で公開
    @Published var accounts: [AccountKey: Account] = [:]
    @Published var names: [String] = []

    init() {
        loadAccounts()
    }
    
    func displayName(for key: AccountKey) -> String {
        guard let account = accounts[key] else {
            return ""
        }
        return "\(account.username)@\(account.serverAddress)"
    }

    func saveAccount(_ account: Account) {
        let key = "\(account.serverAddress)|\(account.username)"
        if let data = try? JSONEncoder().encode(account) {
            keychain[data: key] = data
        }
        loadAccounts() // データを保存したら再読み込み
    }

    func loadAccounts() {
        var newAccounts: [AccountKey: Account] = [:]
        for key in (try? keychain.allKeys()) ?? [] {
            if let data = keychain[data: key],
               let account = try? JSONDecoder().decode(Account.self, from: data) {
                newAccounts[key] = account
            }
        }
        DispatchQueue.main.async {
            self.accounts = newAccounts
            self.names = newAccounts.values.map { "\($0.serverAddress)|\($0.username)" }
        }
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

class LoginModel: ObservableObject {
    @State public var accessToken = ""
    
    func getUserInfo(server: String, token: String, completion: @escaping (Bool, String?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(server)/Users") else {
            completion(false, nil)
            return
        }
        
        guard let url = urlComponents.url else {
            completion(false, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("start")
            if let error = error {
                print(error)
                completion(false, nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                print("http response error")
                completion(false, nil)
                return
            }
            
            do {
                // json
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    if let json = json.first {
                        if let string = json["Id"] as? String {
                            completion(true, string)
                        }
                    }
                }
                completion(false, nil)
            } catch {
                completion(false, nil)
            }
        }.resume()
    }
    
    func login(server: String, username: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(server)/Users/AuthenticateByName") else {
            print("\(server) - error?")
            completion(false, nil)
            return
        }
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Emby UserId=\"sonson\", Client=\"SwiftEmby\", Device=\"iOS\", DeviceId=\"sonson\", Version=\"1.0.0.0\""
        ]
        
        let payload: [String: Any] = [
            "Username": username,
            "Pw": password
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                print(error)
                guard let httpResponse = response as? HTTPURLResponse, let data = data, error == nil else {
                    completion(false, nil)
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let token = json["AccessToken"] as? String {
                        completion(true, token)
                    } else {
                        completion(false, nil)
                    }
                } else {
                    completion(false, nil)
                }
            }.resume()
        } catch {
            completion(false, nil)
        }
    }
}
