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
    case invalidURL
    case invalidUser
}

class APIClient {
    let authProviding: AuthProviding
    
    init(authProviding: AuthProviding) {
        self.authProviding = authProviding
    }
        
    let decoder = JSONDecoder()
    
    func userInfo() async throws -> User {
        
        let (server, token, userID) = try getBasicInfomation()
        
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

    func fetchUserView(with query: [String:String]=[:]) async throws -> [BaseItem] {
        
        let (server, token, userID) = try getBasicInfomation()
        
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
        
    func searchItem(query: String) async throws -> [BaseItem] {
        
        let (server, token, userID) = try getBasicInfomation()
        
        guard var urlComponents = URLComponents(string: "\(server)/Items") else {
            throw APIClientError.cannotCreateURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "SearchTerm", value: query),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "IncludeItemTypes", value: "Video,BoxSet,Episode"),
            URLQueryItem(name: "Fields", value: "BasicSyncInfo"),
            URLQueryItem(name: "userId", value: userID)]
        
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
    
    func fetchItems(parent: BaseItem, with query: [String:String]=[:]) async throws -> [BaseItem] {
        
        let (server, token, userID) = try getBasicInfomation()
        
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
    
    func getBasicInfomation() throws -> (String, String, String) {
        
        guard let server = authProviding.server else {
            throw APIClientError.invalidURL
        }
        guard let token = authProviding.token else {
            throw APIClientError.tokenIsNil
        }
        guard let userID = authProviding.userID else {
            throw APIClientError.invalidUser
        }
        
        return (server, token, userID)
    }
    
    func fetchItemDetail(of itemID: String) async throws -> BaseItem {
        let (server, token, userID) = try getBasicInfomation()
        
        guard let urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Items/\(itemID)") else {
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
        
        if let str = String(data: data, encoding: .utf8) {
            print(str)
        }
        
        let object = try decoder.decode(BaseItem.self, from: data)
        
        return object
    }
    
    func putUserData(to itemID: String, data: Data) async throws {
        let (server, token, userID) = try getBasicInfomation()
        
        guard let urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Items/\(itemID)/UserData") else {
            throw APIClientError.cannotCreateURL
        }
        guard let url = urlComponents.url else {
            throw APIClientError.cannotCreateURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
            throw APIClientError.unauthorized
        }
    }
}
