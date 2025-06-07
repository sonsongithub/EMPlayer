//
//  CollectionViewStrategy.swift
//  EMPlayer
//
//  Created by sonson on 2025/06/07.
//

#if os(iOS) || os(tvOS)

import SwiftUI

struct CollectionViewStrategyKey: EnvironmentKey {
    static let defaultValue: CollectionViewStrategy = .default
}

extension EnvironmentValues {
    var collectionViewStrategy: CollectionViewStrategy {
        get { self[CollectionViewStrategyKey.self] }
        set { self[CollectionViewStrategyKey.self] = newValue }
    }
}

struct CollectionItemStrategyKey: EnvironmentKey {
    static let defaultValue: CollectionItemStrategy = .default
}

extension EnvironmentValues {
    var collectionItemStrategy: CollectionItemStrategy {
        get { self[CollectionItemStrategyKey.self] }
        set { self[CollectionItemStrategyKey.self] = newValue }
    }
}

struct CollectionItemStrategy {
    let isPad: Bool
    let isPortrait: Bool
    
    let verticalSpacing: CGFloat
    let ratioOfTeaserToHeight: CGFloat
    let titlePadding: EdgeInsets
    let overviewPadding: EdgeInsets
    let titleLineLimit: Int
    let titleFont: Font
    let overviewFont: Font
    let titleColor: Color
    let overviewColor: Color
    
    init(screenSize: CGSize) {
#if os(iOS) || os(tvOS)
        isPortrait = screenSize.height >= screenSize.width
        isPad = UIDevice.current.userInterfaceIdiom == .pad
        switch (isPad, isPortrait) {
        case (true, true):
            // iPad in portrait
            do{}
        case (true, false):
            // iPad in landscape
            do{}
        case (false, true):
            // iPhone in portrait
            do{}
        case (false, false):
            // iPhone in landscape
            do{}
        }
        verticalSpacing = 0
        ratioOfTeaserToHeight = 0.75
        titleLineLimit = 2
        titlePadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        overviewPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        titleFont = .body
        overviewFont = .caption
        titleColor = .primary
        overviewColor = .secondary
#elseif os(tvOS)
        verticalSpacing = 4
        ratioOfTeaserToHeight = 0.7
#endif
    }
    
    static func createFrom(parent: CollectionViewStrategy) -> CollectionItemStrategy {
        return CollectionItemStrategy(screenSize: parent.screenSize)
    }
    
    static let `default` = CollectionItemStrategy(screenSize: CGSize(width: 375, height: 667))
    
    static func resolve(using geometry: GeometryProxy) -> CollectionItemStrategy {
        let size = geometry.size
        return CollectionItemStrategy(screenSize: size)
    }
}

struct CollectionViewStrategy {
    let isPad: Bool
    let isPortrait: Bool
    let screenSize: CGSize
    let itemsPerRow: Int
    let horizontalSpacing: CGFloat
    let itemAspectRatio: CGFloat
    let verticalSpacing: CGFloat
    
    init(screenSize: CGSize) {
        self.screenSize = screenSize
#if os(iOS)
        isPortrait = screenSize.height >= screenSize.width
        isPad = UIDevice.current.userInterfaceIdiom == .pad
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
        horizontalSpacing = 16
        itemAspectRatio = 5.5 / 3.0
        verticalSpacing = 20
#elseif os(tvOS)
        isPortrait = false
        isPad = false
        verticalSpacing = 4
        itemsPerRow = 6
        horizontalSpacing = 16
        itemAspectRatio = 5.5 / 3.0
#endif
    }
    
    static let `default` = CollectionViewStrategy(screenSize: CGSize(width: 375, height: 667))
    
    static func resolve(using geometry: GeometryProxy) -> CollectionViewStrategy {
        let size = geometry.size
        return CollectionViewStrategy(screenSize: size)
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
