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
    
    var body: some Scene {
        WindowGroup {
            RootView(appState: self.appState).environmentObject(appState)
        }
    }
}
