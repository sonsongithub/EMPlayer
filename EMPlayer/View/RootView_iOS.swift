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
    
    var body: some View {
        NavigationStack(path: $drill.stack) {
            List {
                if let root = drill.root {
                    ForEach(root.children, id: \.id) { child in
                        Button {
                            drill.stack.append(child)
                        } label: {
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
                    CollectionView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .navigationTitle(base.name)
                case let .series(base):
                    CollectionView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .navigationTitle(base.name)
                case let .boxSet(base):
                    CollectionView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .navigationTitle(base.name)
                case let .season(base):
                    CollectionView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .navigationTitle(base.name)
                case .movie(let base), .episode(let base):
                    MovieView(item: base,
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

#endif
