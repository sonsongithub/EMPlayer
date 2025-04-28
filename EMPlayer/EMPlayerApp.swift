//
//  EMPlayerApp.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

import SwiftUI

@main
struct EMPlayerApp: App {
    @StateObject private var appState: AppState
    @StateObject private var accountManager = AccountManager()
    @StateObject private var authService    = AuthService()
    @StateObject private var repository: ItemRepository
    @StateObject private var serverDiscovery = ServerDiscoveryModel()
    
    init() {
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        _repository = StateObject(wrappedValue: ItemRepository(authProviding: appState))
    }
    
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            MacOSRootView(rootViewController: MacOSRootViewController(appState: appState))
                .environmentObject(appState)
                .environmentObject(repository)
                .environmentObject(accountManager)
                .environmentObject(serverDiscovery)
                .environmentObject(authService)
        }
        #else
        WindowGroup {
            RootView(rootViewController: RootViewController(appState: appState)).environmentObject(appState)
        }
        #endif
    }
}
