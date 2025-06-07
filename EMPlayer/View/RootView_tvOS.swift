//
//  RootView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/03.
//

import SwiftUI

#if os(tvOS)

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var drill: DrillDownStore
    
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
            .navigationDestination(for: ItemNode.self) { node in
                switch node.item {
                case .collection(_):
                    CollectionView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .buttonStyle(.borderless)
                case .series(_):
                    SeriesView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .ignoresSafeArea(edges: [.top, .bottom])
                case .boxSet(_):
                    CollectionView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
                        .buttonStyle(.borderless)
                case .season(_):
                    ItemNodeView(node: node)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(authService)
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
