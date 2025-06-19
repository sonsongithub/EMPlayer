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
                DestinationRouter(node: node)
            }
        }
        .onAppear() {
            if appState.isAuthenticated {
                guard drill.root == nil else { return }
                Task {
                    drill.reset()
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
