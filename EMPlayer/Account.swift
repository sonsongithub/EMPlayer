//
//  Account.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

import SwiftUI

//{"Name":"最終日と彼女-ギリカノ-","ServerId":"39d8b1de74624e758f36e494679f4cbd","Id":"11341","RunTimeTicks":14300940000,"IndexNumber":4,"ParentIndexNumber":3,"IsFolder":false,"Type":"Episode","ParentLogoItemId":"11206","ParentBackdropItemId":"11206","ParentBackdropImageTags":["d30197cb022d0a6672c5cdadf9f8fc4d"],"SeriesName":"彼女、お借りします","SeriesId":"11206","SeasonId":"11320","SeriesPrimaryImageTag":"d44bfb3e31b55fe8e63bfbed235933a9","SeasonName":"シーズン 3","ImageTags":{"Primary":"e51222b67c3124b79599c56b2b1285f0"},"BackdropImageTags":[],"ParentLogoImageTag":"c5b91121356e0aaf9bdeed7f69e2ec3c","MediaType":"Video"}

// ログインモデル
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
