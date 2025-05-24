//
//  TVTabView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/24.
//

import SwiftUI

#if os(tvOS)

struct TVTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var drill: DrillDownStore
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            if self.appState.isAuthenticated {
                RootView()
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
                    .environmentObject(drill)
                    .environmentObject(accountManager)
                    .environmentObject(serverDiscovery)
                    .environmentObject(authService)
                    .tag(0)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                Text("a")
                    .tag(1)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
            }
            AuthenticationView()
                .environmentObject(appState)
                .environmentObject(itemRepository)
                .environmentObject(drill)
                .environmentObject(accountManager)
                .environmentObject(serverDiscovery)
                .environmentObject(authService)
                .tag(2)
                .tabItem {
                    Image(systemName: "person")
                    Text("Account")
                }
        }
        .onChange(of: appState.isAuthenticated) {
            if appState.isAuthenticated {
                appState.selectedTab = 0
            }
        }
    }
}

#endif
