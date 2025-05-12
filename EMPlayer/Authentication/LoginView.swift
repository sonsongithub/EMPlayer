//
//  LoginView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

#if os(iOS)

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var authService: AuthService
    
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let server: String
    

    init(server: String) {
        self.server = server
    }
    
    var body: some View {
        VStack {
            Text("Login: \(String(describing: self.server))")
                .font(.title2)
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
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
        
        Task {
            do {
                let authenticationResponse = try await self.authService.login(server: server, user: username, pass: password)
                let account = Account(server: server, username: authenticationResponse.user.name, userID: authenticationResponse.user.id, token: authenticationResponse.accessToken)
                DispatchQueue.main.async {
                    self.accountManager.saveAccount(account)
                    self.appState.isAuthenticated = true
                    self.appState.userID = account.userID
                    self.appState.server = account.server
                    self.appState.token = account.token
//                    self.isLoading = false
//                    self.errorMessage = nil
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
//                    self.isLoading = false
//                    self.errorMessage = error.localizedDescription
                }
            }
        }
//        isLoading = true
//        errorMessage = nil
//        Task {
//            do {
//                let authenticationResponse = try await self.apiClient.login(server: self.server, username: username, password: password)
//                let account = Account(server: self.server, username: authenticationResponse.user.name, userID: authenticationResponse.user.id, token: authenticationResponse.accessToken)
//                DispatchQueue.main.async {
//                    self.accountManager.saveAccount(account)
//                    self.appState.isAuthenticated = true
//                    self.appState.userID = account.userID
//                    self.appState.server = account.server
//                    self.appState.token = account.token
//                    self.isLoading = false
//                    self.errorMessage = nil
//                }
//            } catch {
//                print(error)
//                DispatchQueue.main.async {
//                    self.isLoading = false
//                    self.errorMessage = error.localizedDescription
//                }
//            }
//        }
    }
}

#Preview {
    let accountManager = AccountManager()
    let appState = AppState()
    return LoginView(server: "http://localhost:8080")
        .environmentObject(accountManager)
        .environmentObject(appState)
}

#endif
