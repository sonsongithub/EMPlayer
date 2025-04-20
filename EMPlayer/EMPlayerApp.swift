//
//  EMPlayerApp.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

import SwiftUI

@main
struct EMPlayerApp: App {
    let appState = AppState()
    let accountManager = AccountManager()
    let serverDiscovery = ServerDiscoveryModel()
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            MacOSRootView(rootViewController: MacOSRootViewController(appState: appState))
                .environmentObject(appState)
                .environmentObject(accountManager)
                .environmentObject(serverDiscovery)
        }
        #else
        WindowGroup {
            RootView(rootViewController: RootViewController(appState: appState)).environmentObject(appState)
        }
        #endif
    }
}
