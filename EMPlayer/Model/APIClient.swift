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
        
        guard let server = authProviding.server else {
            throw APIClientError.invalidURL
        }
        guard let token = authProviding.token else {
            throw APIClientError.tokenIsNil
        }
        guard let userID = authProviding.userID else {
            throw APIClientError.invalidUser
        }
        
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
    
//    def search_item(query, server=EMBY_SERVER, api_key=API_KEY):
//        url = f"{server}/Items"
//        headers = {"X-Emby-Token": api_key}
//        params = {
//            "SearchTerm": query,  # 検索キーワード
//            "Recursive": "true",  # サブフォルダも含めて検索
//            "IncludeItemTypes": "Episode",  # 映画とシリーズを対象
//            "Fields": "BasicSyncInfo",  # 概要も取得
//            # "Limit": 30,  # 取得する結果の数
//            # "IncludeMedia": "true",
//            # "userId": USER_ID,
//            # "X-Emby-Language":'ja'
//        }
//
//        response = requests.get(url, headers=headers, params=params)
//
//        if response.status_code == 200:
//            return response.json()
//        else:
//            raise Exception(f"Error searching items: {response.status_code} - {response.text}")
    
    func searchItem(server: String, userID: String, token: String, query: String) async throws -> [BaseItem] {
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
