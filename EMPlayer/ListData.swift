//
//  ListData.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

import SwiftUI

class UserViewsLoader : ObservableObject {
    
    @Published var movies: [BaseItem] = []
    
    func login(server: String, token: String, userID: String, completion: @escaping (Bool, String?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Views") else {
            completion(false, nil)
            return
        }
        urlComponents.queryItems?.append(URLQueryItem(name: "Recursive", value: "true"))
        urlComponents.queryItems = [
            
        ]
        urlComponents.queryItems?.append(URLQueryItem(name: "Fields", value: "BasicSyncInfo"))
        
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
            
            if let string = String(data: data, encoding: .utf8) {
                print(string)
            }
            
            
            DispatchQueue.main.async {
                self.movies.removeAll()
                do {
                    let result = try JSONDecoder().decode(QueryResult<BaseItem>.self, from: data)
                    let items = result.items
                    print(items)
                    for item in items {
                        self.movies.append(item)
                    }
                    
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
    
}
