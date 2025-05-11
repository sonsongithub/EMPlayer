//
//  LoginToServerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/06.
//

import SwiftUI

#if os(macOS)
#else

struct LoginToServerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    
    @State private var serverName: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoggingIn: Bool = false
    @State private var loginError: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("", text: $serverName, prompt: Text(verbatim: "https://192.168.10.1:8096"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .textContentType(.none)
                .foregroundColor(.primary)

            TextField("User name", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let error = loginError {
                Text(error)
                    .foregroundColor(.red)
            }

            Button(action: login) {
                if isLoggingIn {
                    ProgressView()
                } else {
                    Text("login")
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
                let authenticationResponse = try await self.authService.login(server: serverName, user: username, pass: password)
                let account = Account(server: serverName, username: authenticationResponse.user.name, userID: authenticationResponse.user.id, token: authenticationResponse.accessToken)
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
    }
}

//#Preview {
//    let accountManager = AccountManager()
//    let appState = AppState()
//    return LoginToServerView()
//        .environmentObject(accountManager)
//        .environmentObject(appState)
//}

#endif
