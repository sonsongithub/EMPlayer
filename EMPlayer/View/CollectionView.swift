//
//  CollectionView.swift
//  EMPlayer
//
//  Created by sonson on 2025/06/14.
//

#if os(tvOS) || os(iOS)

import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @ObservedObject var node: ItemNode
    @Environment(\.collectionViewStrategy) var strategy

    @FocusState private var focusedID: UUID?

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let spacing = strategy.horizontalSpacing
            let itemPerRow = strategy.itemsPerRow
            let columnWidth = (availableWidth - spacing * CGFloat(itemPerRow + 1)) / CGFloat(itemPerRow)
            let height = floor(columnWidth * strategy.itemAspectRatio)

            let columns = Array(repeating: GridItem(.fixed(columnWidth), spacing: spacing), count: itemPerRow)

            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: strategy.verticalSpacing) {
                    ForEach(node.children, id: \.id) { item in
                        CollectionItemView(node: item, isFocused: (focusedID == item.uuid))
                            .frame(width: columnWidth, height: height)
                            .focused($focusedID, equals: item.uuid)
                            .zIndex(focusedID == item.uuid ? 1 : 0)
                            .environmentObject(appState)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .environment(\.collectionItemStrategy, CollectionItemStrategy.createFrom(parent: strategy))
                    }
                }
                .padding(.horizontal, spacing)
            }
        }
        .onAppear {
            Task {
                await node.loadChildren(using: itemRepository)
            }
        }
    }
}

#Preview {
    let appState = AppState()
    let drill = DrillDownStore()
    let itemRepository = ItemRepository(authProviding: appState)
    
    let children = (0..<20).map { _ in
        return ItemNode(item: BaseItem.generateRandomItem(type: .series))
    }
    let node = ItemNode(item: BaseItem.generateRandomItem(type: .collectionFolder), children: children)
    
    CollectionView(node: node)
        .environmentObject(appState)
        .environmentObject(itemRepository)
        .environmentObject(drill)
        .frame(width: 1920, height: 1080)
}

#endif
