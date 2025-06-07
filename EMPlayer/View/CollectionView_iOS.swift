////
////  CollectionView.swift
////  EMPlayer
////
////  Created by sonson on 2025/02/16.
////

import SwiftUI

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#if os(iOS)

struct CollectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @ObservedObject var node: ItemNode
    @Environment(\.collectionViewStrategy) var strategy
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let itemPerRow = strategy.itemsPerRow
            let columnWidth = (availableWidth - (strategy.horizontalSpacing * CGFloat(itemPerRow + 1))) / CGFloat(itemPerRow)
            let height = floor(columnWidth * strategy.itemAspectRatio)
            ScrollView {
                VStack(alignment: .leading, spacing: strategy.verticalSpacing) {
                    let rows = self.node.children.chunked(into: itemPerRow)
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        RowView(items: rows[rowIndex], width: columnWidth, height: height)
                            .environmentObject(appState)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .environment(\.collectionViewStrategy, strategy)
                    }
                }
            }.frame(maxWidth: .infinity)
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
