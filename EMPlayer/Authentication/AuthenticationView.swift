//
//  AuthenticationView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/03.
//

import SwiftUI

#if os(macOS)

#elseif os(iOS)

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ServerSelectionView()
                .environmentObject(appState)
                .environmentObject(accountManager)
                .environmentObject(authService)
                .environmentObject(serverDiscovery)
                .navigationTitle("Select server")
                .onChange(of: appState.server) {
                    print("server updated")
                    if appState.ready {
                        isPresented = false
                    }
                }
                .onChange(of: appState.token) {
                    print("token updated")
                    if appState.ready {
                        isPresented = false
                    }
                }
                .onChange(of: appState.userID) {
                    print("userID updated")
                    if appState.ready {
                        isPresented = false
                    }
                }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

#elseif os(tvOS)

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    
    var body: some View {
        NavigationStack {
            ServerSelectionView()
                .environmentObject(appState)
                .environmentObject(accountManager)
                .environmentObject(authService)
                .environmentObject(serverDiscovery)
                .onChange(of: appState.server) {
                    print("server updated")
                    if appState.ready {
                    }
                }
                .onChange(of: appState.token) {
                    print("token updated")
                    if appState.ready {
                    }
                }
                .onChange(of: appState.userID) {
                    print("userID updated")
                    if appState.ready {
                    }
                }
        }
    }
}

#endif
