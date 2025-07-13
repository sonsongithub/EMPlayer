//
//  DestinationRouter.swift
//  EMPlayer
//
//  Created by sonson on 2025/06/16.
//

#if os(iOS) || os(tvOS)

import SwiftUI

struct DestinationRouter: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var drill: DrillDownStore
    
    let node: ItemNode

    var body: some View {
        switch node.item {
        case let .collection(base), let .boxSet(base):
            GeometryReader { geometry in
                let strategy = CollectionViewStrategy.resolve(using: geometry)
                CollectionView(node: node)
                    .environment(\.collectionViewStrategy, strategy)
#if os(tvOS)
                    .buttonStyle(.borderless)
#elseif os(iOS)
                    .navigationTitle(base.name)
#endif
            }
        case let .series(base):
            SeriesView(node: node)
#if os(tvOS)
//                .ignoresSafeArea(edges: .top) 
//                .ignoresSafeArea(edges: [.bottom])
#elseif os(iOS)
                .navigationTitle(base.name)
#endif
        case let .season(base):
            GeometryReader { geometry in
                let strategy = CollectionViewStrategy.resolve(using: geometry)
                CollectionView(node: node)
                    .environment(\..collectionViewStrategy, strategy)
#if os(iOS)
                    .navigationTitle(base.name)
#endif
            }
        case .movie(let base), .episode(let base), .musicVideo(let base):
            MovieView(item: base,
                      appState: appState,
                      itemRepository: itemRepository) {
                appState.playingItem = nil
            }
        default:
            Text("error")
        }
    }
}

#endif
