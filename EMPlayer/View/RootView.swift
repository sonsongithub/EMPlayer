//
//  RootView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/03.
//

import SwiftUI

#if os(macOS)
#else

struct ItemNodeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore

    @ObservedObject var node: ItemNode

    var body: some View {
        List {
            ForEach(node.children, id: \.id) { child in
                NavigationLink(value: child) {
                    Text(child.display())
                }
            }
        }
        .onAppear {
            Task {
                switch node.item {
                case let .collection(base), let .series(base), let .boxSet(base), let .season(base):
                    Task {
                        let items = try await self.itemRepository.children(of: base)
                        print("items: \(items.count)")
                        let children = items.map({ ItemNode(item: $0)})
                        DispatchQueue.main.async {
                            node.children = children
                        }
                    }
                default:
                    do {}
                }
            }
        }
    }
}

#endif

#if os(iOS)

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    
    @EnvironmentObject var drill: DrillDownStore
    
    @State private var showAuthSheet = false
    
    var body: some View {
        NavigationStack() {
            List {
                if let root = drill.root {
                    ForEach(root.children, id: \.id) { child in
                        NavigationLink(value: child) {
                            Text(child.display())
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        self.showAuthSheet = true
                    }) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .navigationTitle(appState.server ?? "")
            .navigationDestination(for: ItemNode.self) { node in
                switch node.item {
                case let .collection(base):
                    ItemNodeView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .navigationTitle(base.name)
                case let .series(base):
                    ItemNodeView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .navigationTitle(base.name)
                case let .boxSet(base):
                    ItemNodeView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .navigationTitle(base.name)
                case let .season(base):
                    ItemNodeView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .navigationTitle(base.name)
                case .movie(let base), .episode(let base):
                    MovieiOSView(item: base,
                                 appState: appState,
                                 itemRepository: itemRepository,) {
                        appState.playingItem = nil
                    }
                                 .environmentObject(itemRepository)
                                 .environmentObject(drill)
                                 .environmentObject(appState)
                                 .environmentObject(accountManager)
                                 .environmentObject(authService)
                default:
                    Text("error")
                }
            }
        }
        .onChange(of: appState.token) {
            if appState.isAuthenticated {
                drill.reset()
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
        .sheet(isPresented: $showAuthSheet) {
            AuthenticationView(isPresented: $showAuthSheet)
                .environmentObject(appState)
                .environmentObject(accountManager)
                .environmentObject(authService)
        }
    }
}

#elseif os(tvOS)

struct TVRootView: View {
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

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var drill: DrillDownStore
    
    var body: some View {
        NavigationStack() {
            List {
                if let root = drill.root {
                    ForEach(root.children, id: \.id) { child in
                        NavigationLink(value: child) {
                            Text(child.display())
                        }
                    }
                }
            }
            .navigationDestination(for: ItemNode.self) { node in
                switch node.item {
                case .collection(_):
                    ItemNodeView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                case .series(_):
                    ItemNodeView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                case .boxSet(_):
                    ItemNodeView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                case .season(_):
                    ItemNodeView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                case .movie(let base), .episode(let base):
                    MovietvOSView(item: base,
                                 appState: appState,
                                 itemRepository: itemRepository,) {
                        appState.playingItem = nil
                    }
                                 .environmentObject(itemRepository)
                                 .environmentObject(drill)
                                 .environmentObject(appState)
                                 .environmentObject(accountManager)
                                 .environmentObject(authService)
                default:
                    Text("error")
                }
            }
        }
        .onAppear() {
            if appState.isAuthenticated {
                drill.reset()
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
        .onChange(of: appState.token) {
            if appState.isAuthenticated {
                drill.reset()
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
