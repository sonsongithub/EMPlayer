//
//  ListData.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

import SwiftUI

struct MovieInfo: Hashable {
    let id: String
    let name: String
    let imageURL: URL?
}

class MovieLoader : ObservableObject {
    
    @Published var movies: [BaseItem] = []
    
    func login(server: String, token: String, userID: String, completion: @escaping (Bool, String?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Views") else {
            completion(false, nil)
            return
        }
//        guard var urlComponents = URLComponents(string: "\(server)/Items") else {
//            completion(false, nil)
//            return
//        }
        
//        /Users/{UserId}/Views
        
        urlComponents.queryItems = [
//            URLQueryItem(name: "SearchTerm", value: ""),
//            URLQueryItem(name: "Recursive", value: "true"),
//            URLQueryItem(name: "IncludeItemTypes", value: "Movie")
        ]
        
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
                    print(result)
                    let items = result.items
                    
                    for item in items {
                        self.movies.append(item)
//                        self.movies.append(MovieInfo(id: item.id, name: item.name, imageURL: item.imageTags?.imageURL(server: server, id: item.id)))
                    }
                    
                } catch {
                    print(error)
                }
            }
//            do {
//                    // json
//                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                        if let items = json["Items"] as? [[String: Any]] {
//                            for item in items {
//                                if let name = item["Name"] as? String, let id = item["Id"] as? String {
//                                    self.movies.append(MovieInfo(id: id, name: name, imageURL: nil))
//                                }
//                            }
//                        }
//                    }
//                }
//                if let string = String(data: data, encoding: .utf8) {
//                    print(string)
//                }
//                
//                let decodedItems = try JSONDecoder().decode(QueryResult<BaseItem>.self, from: data)
//                print(decodedItems)
////                /Items/{Id}/Images/{Type}
//                
//                completion(true, nil)
//            } catch {
//                print(error)
//                completion(false, nil)
//            }
        }.resume()
    }
    
}
