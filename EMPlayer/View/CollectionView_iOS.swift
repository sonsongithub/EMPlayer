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

struct CollectionViewStrategyKey: EnvironmentKey {
    static let defaultValue: CollectionViewStrategy = .default
}

extension EnvironmentValues {
    var collectionViewStrategy: CollectionViewStrategy {
        get { self[CollectionViewStrategyKey.self] }
        set { self[CollectionViewStrategyKey.self] = newValue }
    }
}

struct CollectionViewStrategy {
    
    let itemsPerRow: Int
    
    init(isPad: Bool, isPortrait: Bool) {
        #if os(iOS) || os(tvOS)
        switch (isPad, isPortrait) {
            case (true, true):
                self.itemsPerRow = 4
            case (true, false):
                self.itemsPerRow = 6
            case (false, true):
                self.itemsPerRow = 2
            case (false, false):
                self.itemsPerRow = 3
        }
        #else
        self.itemsPerRow = 6
        #endif
    }
    
    static let `default` = CollectionViewStrategy(isPad: false, isPortrait: true)
    
    static func resolve(using geometry: GeometryProxy) -> CollectionViewStrategy {
        let size = geometry.size
        let isPortrait = size.height >= size.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        return CollectionViewStrategy(isPad: isPad, isPortrait: isPortrait)
    }
    
}

#if os(iOS)

struct CollectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @ObservedObject var node: ItemNode
    @Environment(\.collectionViewStrategy) var strategy
    
    let horizontalSpacing: CGFloat = 16
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let itemPerRow = strategy.itemsPerRow
            let columnWidth = (availableWidth - (horizontalSpacing * CGFloat(itemPerRow + 1))) / CGFloat(itemPerRow)
            let height = floor(columnWidth * 4 / 3.0 + 60)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let rows = self.node.children.chunked(into: itemPerRow)
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        RowView(items: rows[rowIndex], width: columnWidth, height: height, horizontalSpacing: horizontalSpacing)
                            .environmentObject(appState)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
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
