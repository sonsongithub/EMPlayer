//
//  EMPlayerApp.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

import SwiftUI

@main
struct EMPlayerApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif
    @StateObject private var appState: AppState
    @StateObject private var accountManager = AccountManager()
    @StateObject private var authService    = AuthService()
    @StateObject private var itemRepository: ItemRepository
    @StateObject private var serverDiscovery = ServerDiscoveryModel()
    @StateObject private var drill = DrillDownStore()
    
    init() {
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        _itemRepository = StateObject(wrappedValue: ItemRepository(authProviding: appState))
    }
    
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            MacOSRootView()
                .environmentObject(appState)
                .environmentObject(itemRepository)
                .environmentObject(accountManager)
                .environmentObject(serverDiscovery)
                .environmentObject(authService)
                .environmentObject(drill)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        #else
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(itemRepository)
                .environmentObject(drill)
                .environmentObject(accountManager)
                .environmentObject(serverDiscovery)
                .environmentObject(authService)
        }
        #endif
    }
}

#if os(macOS)
private class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#endif
