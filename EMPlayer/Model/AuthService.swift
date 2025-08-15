//
//  AuthService.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/28.
//

import SwiftUI

final class AuthService: ObservableObject {
    @Published private(set) var token: String? = nil
    
    private let apiClient = AuthClient()
    
    func login(server: String, user: String, pass: String) async throws -> AuthenticationResponse {
        let authenticationResponse = try await apiClient.login(server: server, username: user, password: pass)
        await MainActor.run {
            self.token = authenticationResponse.accessToken
        }
        return authenticationResponse
    }
    
    func logout() {
        token = nil
    }
    
    func ensureValidToken() async throws {
//        if /* expired */ { token = try await api.refreshToken(old: token!) }
    }
}
