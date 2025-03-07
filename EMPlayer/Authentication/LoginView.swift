//
//  LoginView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let server: String
    
    let apiClient = APIClient()

    init(server: String) {
        self.server = server
    }
    
    var body: some View {
        VStack {
            Text("Login: \(String(describing: self.appState.server))")
                .font(.title2)
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            Button("Login") {
                login()
            }
            .disabled(username.isEmpty || password.isEmpty || isLoading)
            .padding()
        }
        .navigationTitle("Login to server")
    }

    func login() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let authenticationResponse = try await self.apiClient.login(server: self.server, username: username, password: password)
                let account = Account(serverAddress: self.server, username: authenticationResponse.user.name, userID: authenticationResponse.user.id, token: authenticationResponse.accessToken)
                DispatchQueue.main.async {
                    self.accountManager.saveAccount(account)
                    self.appState.isAuthenticated = true
                    self.appState.userID = account.userID
                    self.appState.server = account.serverAddress
                    self.appState.token = account.token
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
