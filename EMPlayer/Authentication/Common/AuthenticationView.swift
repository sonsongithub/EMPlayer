//
//  AuthenticationView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/03.
//

import SwiftUI

#if os(tvOS) || os(iOS)

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    
    @State private var selectedServer: ServerInfo?
    @State private var navigateToLogin = false
    
    @State private var showAlert = false
    @State private var showErrorAlert = false
    
    @State private var isNavigating = false

    #if os(iOS)
    @Binding var isPresented: Bool
    #endif
    
    var body: some View {
        NavigationStack {
            List {
                ServerHistoryView {
                    isNavigating = true
                } didPushTrash: {
                    showAlert = true
                } didPushServer: { serverInfo in
                    self.selectedServer = serverInfo
                } didPushHistory: { account in
                    self.appState.isAuthenticated = true
                    self.appState.userID = account.userID
                    self.appState.server = account.server
                    self.appState.token = account.token
                    self.selectedServer = nil
                }
            }
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
            .sheet(isPresented: $isNavigating) {
                LoginToServerView()
                    .environmentObject(accountManager)
                    .environmentObject(appState)
            }
            .sheet(item: $selectedServer) { server in
                LoginSheetView(selectedServer: $selectedServer)
                    .environmentObject(appState)
                    .environmentObject(accountManager)
                    .environmentObject(itemRepository)
                    .environmentObject(authService)
            }
            #if os(iOS)
            .navigationTitle("Login")
            #endif
            .onChange(of: appState.token) {
                print("token updated")
                if appState.ready {
                    selectedServer = nil
                    isNavigating = false
                }
            }
            .onChange(of: appState.userID) {
                print("userID updated")
                if appState.ready {
                    selectedServer = nil
                    isNavigating = false
                }
            }
    }
}

#endif
