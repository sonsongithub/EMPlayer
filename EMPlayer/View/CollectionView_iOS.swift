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
    
    let minWidth: CGFloat = 120
    let maxWidth: CGFloat = 200
    let horizontalSpacing: CGFloat = 32
    let space: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let itemPerRow = max(1, Int(availableWidth / maxWidth))
            let columnWidth = max(minWidth, (availableWidth - (horizontalSpacing * CGFloat(itemPerRow + 1))) / CGFloat(itemPerRow))
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
}

#endif
