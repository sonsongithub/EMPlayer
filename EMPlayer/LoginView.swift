//
//  LoginView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let loginModel = LoginModel()

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
        
        guard let server = self.appState.server else { return }
        loginModel.login(server: server, username: username, password: password) { success, token in
            if success {
                if let token = token {
                    self.loginModel.getUserInfo(server: server, token: token) { success, id in
                        if let id = id {
                            DispatchQueue.main.async {
                                self.appState.userID = id
                                self.appState.token = token
                                self.appState.saveToUserDefaults()
                            }
                        }
                        isLoading = true
                    }
                } else {
                    isLoading = false
                }
            } else {
                print("error")
                isLoading = false
            }
        }
    }
}
