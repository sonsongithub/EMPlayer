//
//  APIClient.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/03.
//

import Foundation
import Combine

enum APIClientError: Error {
    case cannotCreateURL
    case tokenIsNil
    case unauthorized
}

class APIClient {
    let decoder = JSONDecoder()
    
    init() {
    }
    
    func login(server: String, username: String, password: String) async throws -> AuthenticationResponse {
        guard let urlComponents = URLComponents(string: "\(server)/Users/AuthenticateByName") else {
            throw APIClientError.cannotCreateURL
        }
        guard let url = urlComponents.url else {
            throw APIClientError.cannotCreateURL
        }
        
        let payload: [String: Any] = [
            "Username": username,
            "Pw": password
        ]
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Emby UserId=\"sonson\", Client=\"SwiftEmby\", Device=\"iOS\", DeviceId=\"sonson\", Version=\"1.0.0.0\""
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let text = String(data: data, encoding: .utf8) {
            print(text)
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIClientError.unauthorized
        }
        
        return try decoder.decode(AuthenticationResponse.self, from: data)
    }
    
    func getUserInfo(server: String, userID: String, token: String) async throws -> User {
        guard let urlComponents = URLComponents(string: "\(server)/Users/\(userID)") else {
            throw APIClientError.cannotCreateURL
        }
        guard let url = urlComponents.url else {
            throw APIClientError.cannotCreateURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIClientError.unauthorized
        }
        
        if let text = String(data: data, encoding: .utf8) {
            print(text)
        }
        
        return try decoder.decode(User.self, from: data)
    }

    func fetchUserView(server: String, userID: String, token: String, with query: [String:String]=[:]) async throws -> [BaseItem] {
        
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Views") else {
            throw APIClientError.cannotCreateURL
        }
        for (key, value) in query {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        guard let url = urlComponents.url else {
            throw APIClientError.cannotCreateURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIClientError.unauthorized
        }
        
        let object = try decoder.decode(QueryResult<BaseItem>.self, from: data)
        
        return object.items
    }
    
    func fetchItems(server: String, userID: String, token: String, of parent: BaseItem, with query: [String:String]=[:]) async throws -> [BaseItem] {
        
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Items") else {
            throw APIClientError.cannotCreateURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "ParentId", value: parent.id),
        ]
        
        if let collectionType = parent.collectionType {
            if collectionType == .movies {
                urlComponents.queryItems?.append(URLQueryItem(name: "Recursive", value: "true"))
                urlComponents.queryItems?.append(URLQueryItem(name: "IncludeItemTypes", value: "Movie"))
            }
        }
        
        guard let url = urlComponents.url else {
            throw APIClientError.cannotCreateURL
        }
    
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIClientError.unauthorized
        }
        
        let object = try decoder.decode(QueryResult<BaseItem>.self, from: data)
        
        return object.items
    }
    
    func fetchItemDetail(server: String, userID: String, token: String, of item: BaseItem) async throws -> BaseItem {
        
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Items/\(item.id)") else {
            throw APIClientError.cannotCreateURL
        }
        guard let url = urlComponents.url else {
            throw APIClientError.cannotCreateURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIClientError.unauthorized
        }
        
        let object = try decoder.decode(BaseItem.self, from: data)
        
        return object
    }
}
