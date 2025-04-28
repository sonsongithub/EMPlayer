//
//  ServerSelectionView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI
import KeychainAccess

#if os(macOS)
#else

struct ServerSelectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @State private var selectedServer: String?
    @State private var navigateToLogin = false
    @ObservedObject var serverDiscovery = ServerDiscoveryModel()
    
    let apiClient = APIClient()

    @State private var showAlert = false
    @State private var showErrorAlert = false
    
    @State private var isNavigating = false
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Found servers")) {
                    ForEach(serverDiscovery.servers, id: \.self) { server in
                        NavigationLink(value: server) {
                            Text(server.name)
                        }
                    }
                }
                Section(header: Text("History")) {
                    ForEach(accountManager.names, id: \.self) { name in
                        Button(accountManager.displayName(for: name)) {
                            if let account = accountManager.accounts[name] {
                                Task {
                                    do {
                                        let user = try await self.apiClient.getUserInfo(server: account.server, userID: account.userID, token: account.token)
                                        if user.id == account.userID {
                                            appState.server = account.server
                                            appState.token = account.token
                                            appState.userID = account.userID
                                            appState.isAuthenticated = true
                                        } else {
                                            showErrorAlert = true
                                        }
                                    } catch {
                                        showErrorAlert = true
                                        print(error)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Login")
            .navigationDestination(for: ServerInfo.self) { value in
                LoginView(server: value.address).environmentObject(accountManager).environmentObject(appState)
            }
            .alert("Can not login to the server.", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) {}
            })
            .alert("Are you sure to delete your history?", isPresented: $showAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { accountManager.deleteAll() }
            } message: {
                Text("This operation cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isNavigating = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        showAlert = true
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }
            .navigationDestination(isPresented: $isNavigating) {
                LoginToServerView().environmentObject(accountManager).environmentObject(appState)
            }
        }
    }
}

#Preview {
    @Previewable @State var showAuthSheet = false
    let appState = AppState()
    AuthenticationView(isPresented: $showAuthSheet).environmentObject(appState)
}

#endif
