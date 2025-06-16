//
//  TVTabView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/24.
//

import SwiftUI

#if os(tvOS)

struct SearchResultsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    let items: [BaseItem]
    
    @State private var rootNode = ItemNode(item: nil)

    var body: some View {
        CollectionView(node: rootNode, isSearchView: true)
            .navigationTitle("Search Results")
            .onAppear {
                updateNode()
            }
            .onChange(of: items) {
                updateNode()
            }
    }
    
    private func updateNode() {
        let nodes = items
            .filter { $0.type != .unknown }
            .map { ItemNode(item: $0) }
        rootNode.children = nodes
    }
}

struct SearchView: View {
    @State private var query = ""
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @State private var searchResultsView: AnyView? = nil
    
    var body: some View {
        VStack {
            TextField("Search...", text: $query)
                .onSubmit {
                    Task {
                        let results = try await itemRepository.search(query: query)
                        DispatchQueue.main.async {
                            print("Search results: \(results.count)")
                            let view = SearchResultsView(items: results)
                            self.searchResultsView = AnyView(view)
                        }
                    }
                }
            if let searchResultsView {
                searchResultsView
            }
        }
    }
}

struct TVTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var drill: DrillDownStore
    
    @StateObject private var searchDrill = DrillDownStore()
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            if self.appState.isAuthenticated {
                RootView()
                    .tag(0)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                NavigationStack(path: $searchDrill.stack) {
                    SearchView()
                        .environmentObject(searchDrill)
                        .navigationDestination(for: ItemNode.self) { node in
                            DestinationRouter(node: node)
                        }
                }
                .tag(1)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            }
            AuthenticationView()
                .tag(2)
                .tabItem {
                    Image(systemName: "person")
                    Text("Account")
                }
        }
        .onAppear {
            if appState.isAuthenticated {
                appState.selectedTab = 0
            } else {
                appState.selectedTab = 2
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
