//
//  LoginToServerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/06.
//

import SwiftUI

struct LoginToServerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    
    @State private var serverName: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoggingIn: Bool = false
    @State private var loginError: String?
    
    let apiClient = APIClient()

    var body: some View {
        VStack(spacing: 20) {
            Text("ログイン")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("サーバ名", text: $serverName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            TextField("アカウント", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            SecureField("パスワード", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let error = loginError {
                Text(error)
                    .foregroundColor(.red)
            }

            Button(action: login) {
                if isLoggingIn {
                    ProgressView()
                } else {
                    Text("ログイン")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoggingIn)

        }
        .padding()
    }

    func login() {
//        isLoading = true
//        errorMessage = nil
        Task {
            do {
                let authenticationResponse = try await self.apiClient.login(server: serverName, username: username, password: password)
                let account = Account(serverAddress: serverName, username: authenticationResponse.user.name, userID: authenticationResponse.user.id, token: authenticationResponse.accessToken)
                DispatchQueue.main.async {
                    self.accountManager.saveAccount(account)
                    self.appState.isAuthenticated = true
                    self.appState.userID = account.userID
                    self.appState.server = account.serverAddress
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
    }
}
