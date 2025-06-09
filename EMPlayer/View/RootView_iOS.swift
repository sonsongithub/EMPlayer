//
//  RootView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/03.
//

import SwiftUI

#if os(iOS)

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    
    @EnvironmentObject var drill: DrillDownStore
    
    @State private var showAuthSheet = false
    
    @State private var query = ""
    @State private var searchResults: [BaseItem] = []
    
    var body: some View {
        NavigationStack(path: $drill.stack) {
            Group {
                if !searchResults.isEmpty {
                    let nodes = searchResults.map { ItemNode(item: $0) }
                    let rootNode = ItemNode(item: nil, children: nodes)
                    GeometryReader { geometry in
                        let strategy = CollectionViewStrategy.resolve(using: geometry)
                        CollectionView(node: rootNode)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .environmentObject(appState)
                            .environmentObject(accountManager)
                            .environmentObject(authService)
                            .environment(\.collectionViewStrategy, strategy)
                    }
                } else {
                    List {
                        if let root = drill.root {
                            ForEach(root.children, id: \..id) { child in
                                Button {
                                    drill.stack.append(child)
                                } label: {
                                    Text(child.display())
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: query) {
                if query.isEmpty {
                    searchResults = []
                }
            }
            .onSubmit(of: .search) {
                Task {
                    let results = try await itemRepository.search(query: query)
                    DispatchQueue.main.async {
                        print("Search results: \(results.count)")
                        self.searchResults = results
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
            .navigationDestination(for: ItemNode.self) { node in
                switch node.item {
                case let .collection(base):
                    GeometryReader { geometry in
                        let strategy = CollectionViewStrategy.resolve(using: geometry)
                        CollectionView(node: node)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .environmentObject(appState)
                            .environmentObject(accountManager)
                            .environmentObject(authService)
                            .navigationTitle(base.name)
                            .environment(\.collectionViewStrategy, strategy)
                    }
                case let .series(base):
                    SeriesView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .navigationTitle(base.name)
                case let .boxSet(base):
                    GeometryReader { geometry in
                        let strategy = CollectionViewStrategy.resolve(using: geometry)
                        CollectionView(node: node)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .environmentObject(appState)
                            .environmentObject(accountManager)
                            .environmentObject(authService)
                            .navigationTitle(base.name)
                            .environment(\.collectionViewStrategy, strategy)
                    }
                case let .season(base):
                    GeometryReader { geometry in
                        let strategy = CollectionViewStrategy.resolve(using: geometry)
                        CollectionView(node: node)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .environmentObject(appState)
                            .environmentObject(accountManager)
                            .environmentObject(authService)
                            .navigationTitle(base.name)
                            .environment(\..collectionViewStrategy, strategy)
                    }
                case .movie(let base), .episode(let base):
                    MovieView(item: base,
                              appState: appState,
                              itemRepository: itemRepository) {
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
        .sheet(isPresented: $showAuthSheet) {
            AuthenticationView(isPresented: $showAuthSheet)
                .environmentObject(appState)
                .environmentObject(accountManager)
                .environmentObject(authService)
        }
    }
}

#endif
