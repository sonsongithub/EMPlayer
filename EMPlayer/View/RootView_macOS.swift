//
//  RootView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/03.
//

#if os(macOS)

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var drill: DrillDownStore
    
    @State private var showVideoPlayer = false
    @State private var selectedServer: ServerInfo? = nil
    
    @State private var columnVis: NavigationSplitViewVisibility = .all
    
    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVis) {
                Sidebar()
                    .environmentObject(appState)
                    .environmentObject(accountManager)
                    .environmentObject(serverDiscovery)
                    .environmentObject(itemRepository)
                    .environmentObject(authService)
                    .environmentObject(drill)
                    .padding(.trailing, 4)
            } detail: {
                ColumnDrillView()
                    .environmentObject(drill)
                    .environmentObject(itemRepository)
            }
            if let overlay = drill.overlay {
                if case let .movie(base) = overlay.item {
                    MovieView(item: base, app: appState, repo: itemRepository) { drill.overlay = nil }
                        .transition(.opacity)
                        .zIndex(1)
                }
                if case let .episode(base) = overlay.item {
                    MovieView(item: base, app: appState, repo: itemRepository) { drill.overlay = nil }
                        .transition(.opacity)
                        .zIndex(1)
                }
                    
            }
        }
        .onChange(of: appState.token) {
            if appState.token != nil {
                Task {
                    let items = try await itemRepository.root()
                    print("items: \(items.count)")
                    let children = items.map({ ItemNode(item: $0)}).filter({ $0.item != .unknown })
                    DispatchQueue.main.async {
                        drill.root = ItemNode(item: nil, children: children)
                    }
                }
            }
        }
        .onChange(of: appState.isAuthenticated) {
            if appState.isAuthenticated {
                Task {
                    let items = try await itemRepository.root()
                    print("items: \(items.count)")
                    let children = items.map({ ItemNode(item: $0)}).filter({ $0.item != .unknown })
                    DispatchQueue.main.async {
                        drill.root = ItemNode(item: nil, children: children)
                    }
                }
            }
        }
    }
}

#endif
