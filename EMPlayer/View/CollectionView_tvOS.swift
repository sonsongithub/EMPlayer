//
//  CollectionView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/27.
//

#if os(tvOS)

import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @ObservedObject var node: ItemNode

    let itemPerRow: Int = 6
    let space: CGFloat = 64
    let horizontalSpacing: CGFloat = 32
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let columnWidth = (availableWidth - (horizontalSpacing * CGFloat(itemPerRow + 1))) / CGFloat(itemPerRow)
            let height = floor(columnWidth * 4 / 3.0 + 60)
            ScrollView {
                VStack(alignment: .leading, spacing: space) {
                    let rows = self.node.children.chunked(into: itemPerRow)
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        RowView(items: rows[rowIndex], width: columnWidth, height: height, horizontalSpacing: horizontalSpacing)
                            .environmentObject(appState)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                    }
                }.frame(maxWidth: .infinity)
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
                            print("node.children: \(node.children.count)")
                        }
                    }
                default:
                    do {}
                }
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
