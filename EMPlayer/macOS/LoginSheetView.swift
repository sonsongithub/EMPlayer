//
//  LoginSheetView.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/29.
//

import SwiftUI

#if os(macOS)

struct LoginSheetView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @Binding var selectedServer: ServerInfo?
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login to \(self.selectedServer?.address)")
                .font(.headline)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    self.selectedServer = nil
                }
                Spacer()
                Button("Login") {
                    self.login()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 400)
    }
    
    func login() {
        
        guard let server = selectedServer?.address else { return }

        
        Task {
            do {
                let authenticationResponse = try await authService.login(server: server, user: username, pass: password)
                
                appState.server = server
                appState.token = authenticationResponse.accessToken
                appState.userID = authenticationResponse.user.id
                appState.isAuthenticated = true
                
                let user = try await itemRepository.userInfo()
                
                let account = Account(server: server, username: user.name, userID: user.id, token: authenticationResponse.accessToken)
                DispatchQueue.main.async {
                    self.accountManager.saveAccount(account)
                    self.appState.isAuthenticated = true
                    self.appState.userID = account.userID
                    self.appState.server = account.server
                    self.appState.token = account.token
                    self.selectedServer = nil
                    self.drill.reset()
                }
            } catch {
                DispatchQueue.main.async {
                }
                print(error)
            }
        }
    }
}

#endif
