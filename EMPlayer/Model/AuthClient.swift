//
//  RawAuthAPI.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/28.
//

import SwiftUI

class AuthClient {
    
    let decoder = JSONDecoder()
    
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
    
}
