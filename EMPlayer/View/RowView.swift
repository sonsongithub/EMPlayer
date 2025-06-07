//
//  RowView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/27.
//

#if os(tvOS) || os(iOS)

import SwiftUI

struct RowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    
    @EnvironmentObject var drill: DrillDownStore
    @FocusState private var focusedID: UUID?
    @Environment(\.collectionViewStrategy) var parentStrategy
    
    let items: [ItemNode]
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        let strategy = CollectionItemStrategy.createFrom(parent: parentStrategy)
        HStack(spacing: parentStrategy.horizontalSpacing) {
            ForEach(items, id: \.id) { item in
                CollectionItemView(node: item, isFocused: (focusedID == item.uuid))
                    .frame(width: width, height: height)
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
                    .focused($focusedID, equals: item.uuid)
                    .zIndex(focusedID == item.uuid ? 1 : 0)
                    .environment(\.collectionItemStrategy, strategy)
            }
        }
    }
}

#Preview {
    let appState = AppState()
    let drill = DrillDownStore()
    let accountManager = AccountManager()
    let itemRepository = ItemRepository(authProviding: appState)
    
    let children = (0..<20).map { _ in
        return ItemNode(item: BaseItem.generateRandomItem(type: .series))
    }
    let node = ItemNode(item: BaseItem.generateRandomItem(type: .collectionFolder), children: children)
    
    GeometryReader { geometry in
        let strategy = CollectionViewStrategy.resolve(using: geometry)
        CollectionView(node: node)
            .environmentObject(appState)
            .environmentObject(itemRepository)
            .environmentObject(drill)
            .environmentObject(accountManager)
            .environment(\.collectionViewStrategy, strategy)
    }
}

#endif
