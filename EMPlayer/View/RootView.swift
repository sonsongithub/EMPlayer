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
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
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
            print(node)
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
                case .movie(let base), .episode(let base):
                        MovieiOSView(item: base, app: appState, repo: itemRepository)
                default:
                    do {}
                }
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
    
    @State private var showAuthSheet = false
    
    var body: some View {
        NavigationStack {
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
                        MovieiOSView(item: base, app: appState, repo: itemRepository)
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

#endif
