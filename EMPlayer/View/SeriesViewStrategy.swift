//
//  SeriesViewStrategy.swift
//  EMPlayer
//
//  Created by sonson on 2025/06/01.
//

#if os(iOS) || os(tvOS)

import SwiftUI

struct SeriesViewStrategyKey: EnvironmentKey {
    static let defaultValue: SeriesViewStrategy = .default
}

extension EnvironmentValues {
    var seriesViewStrategy: SeriesViewStrategy {
        get { self[SeriesViewStrategyKey.self] }
        set { self[SeriesViewStrategyKey.self] = newValue }
    }
}

struct SeriesViewStrategy {
    let screenSize: CGSize
    let isPad: Bool
    let isPortrait: Bool

    enum ScrollDirection { case vertical, horizontal }
    enum ContentLayout { case portrait, landscape }

    // 全体の戦略
    let scrollDirection: ScrollDirection
    let padding: EdgeInsets
    let pickerMarginTop: CGFloat
    let pickerMarginBottom: CGFloat
    let episodePadding: EdgeInsets

    // Info View
    struct Info {
        let hasImage: Bool
        let height: CGFloat
        let hasTitle: Bool
        let titleFont: Font
        let overviewFont: Font
        let horizontalPadding: CGFloat
    }
    let info: Info

    // Episode View
    struct Episode {
        let layout: ContentLayout
        let width: CGFloat
        let height: CGFloat
        let titleFont: Font
        let titleColor: Color
        let overviewFont: Font
        let overviewColor: Color
        let padding: EdgeInsets
        let space: CGFloat
    }
    let episode: Episode

    #if os(iOS)
    init(size: CGSize) {
        isPad = UIDevice.current.userInterfaceIdiom == .pad
        
        
        if isPad {
            isPortrait = size.height > size.width
            let scroll: ScrollDirection = isPad ? (isPortrait ? .vertical : .horizontal) : .vertical
            let layout: ContentLayout = isPad ? (isPortrait ? .landscape : .portrait) : .landscape
            
            let pickerSize = CGFloat(80)
            
            let infoHeight = (size.height - pickerSize) * 0.5
            let seasonHeight = (size.height - pickerSize) * 0.3
            
            screenSize = size
            scrollDirection = .horizontal
            padding = .init()
            pickerMarginTop = 32
            pickerMarginBottom = 8
            episodePadding = .init(top: 0, leading: 0, bottom: 20, trailing: 0)
            info = Info(
                hasImage: true,
                height: infoHeight,
                hasTitle: false,
                titleFont: .caption,
                overviewFont: .footnote,
                horizontalPadding: 10
            )
            episode = Episode(
                layout: .portrait,
//                width: layout == .landscape ? size.width : 320,
//                height: layout == .landscape ? 200 : seasonHeight,
                width: 320,
                height: layout == .landscape ? seasonHeight : seasonHeight + 100,
                titleFont: .body,
                titleColor: .primary,
                overviewFont: .footnote,
                overviewColor: .secondary,
                padding: .init(top: 0, leading: 10, bottom: 0, trailing: 10),
                space: 30
            )
        } else {
            // iPhone
            isPortrait = size.height > size.width
            let scroll: ScrollDirection = .horizontal
            let layout: ContentLayout = isPortrait ? .portrait : .landscape
            
            let pickerSize = CGFloat(80)
            
            
            screenSize = size
            scrollDirection = scroll
            padding = .init()
            episodePadding = .init(top: 0, leading: 5, bottom: 0, trailing: 10)
            
            if isPortrait {
                
                let infoHeight = (size.height - pickerSize) * 0.5
                let seasonHeight = (size.height - pickerSize) * 0.5
                
                pickerMarginTop = 8
                pickerMarginBottom = 8
                
                info = Info(
                    hasImage: true,
                    height: infoHeight,
                    hasTitle: false,
                    titleFont: .caption,
                    overviewFont: .footnote,
                    horizontalPadding: 10
                )
                
                episode = Episode(
                    layout: layout,
                    width: 300,
                    height: seasonHeight,
                    titleFont: .body,
                    titleColor: .primary,
                    overviewFont: .footnote,
                    overviewColor: .secondary,
                    padding: .init(top: 0, leading: 10, bottom: 0, trailing: 30),
                    space: 10
                )
            } else {
                
                let infoHeight = (size.height - pickerSize) * 0.35
                let seasonHeight = (size.height - pickerSize) * 0.65
                
                pickerMarginTop = 8
                pickerMarginBottom = 8
                
                info = Info(
                    hasImage: false,
                    height: infoHeight,
                    hasTitle: false,
                    titleFont: .caption,
                    overviewFont: .footnote,
                    horizontalPadding: 10
                )
                
                episode = Episode(
                    layout: layout,
                    width: 500,
                    height: seasonHeight,
                    titleFont: .body,
                    titleColor: .primary,
                    overviewFont: .footnote,
                    overviewColor: .secondary,
                    padding: .init(top: 0, leading: 10, bottom: 0, trailing: 30),
                    space: 10
                )
            }
            
        }
    }
    #elseif os(tvOS)
    init(size: CGSize) {
        let scroll: ScrollDirection = .horizontal
        let layout: ContentLayout = .portrait
        
        let pickerSize = CGFloat(80)
        
        let infoHeight = (size.height - pickerSize) * 0.35
        let seasonHeight = (size.height - pickerSize) * 0.6
        
        screenSize = size
        isPad = true
        isPortrait = size.height > size.width
        scrollDirection = scroll
        padding = .init()
        pickerMarginTop = 32
        pickerMarginBottom = 8
        episodePadding = .init(top: 32, leading: 10, bottom: 32, trailing: 10)
        info = Info(
            height: infoHeight,
            hasTitle: true,
            titleFont: .caption,
            overviewFont: .footnote,
            horizontalPadding: 10
        )
        
        episode = Episode(
            layout: layout,
            width: 400,
            height: seasonHeight,
            titleFont: .body,
            titleColor: .primary,
            overviewFont: .footnote,
            overviewColor: .secondary,
            padding: .init(top: 20, leading: 20, bottom: 20, trailing: 20),
            space: 30
        )
    }
    #endif
    
    static func resolve(size geo: CGSize) -> SeriesViewStrategy {
        return SeriesViewStrategy(size: geo)
    }
    
    static let `default` = SeriesViewStrategy.resolve(size: CGSize(width: 1024, height: 768))
    static let `preview` = SeriesViewStrategy.resolve(size: CGSize(width: 1024, height: 768))
    
    static func resolve(using geometry: GeometryProxy) -> SeriesViewStrategy {
        let size = geometry.size
        return SeriesViewStrategy.resolve(size: size)
    }
}

#Preview {
    let appState = AppState()
    let drill = DrillDownStore()
    let itemRepository = ItemRepository(authProviding: appState)
    let seriesNode = ItemNode.dummySeries()
    NavigationStack {
        SeriesView(node: seriesNode)
            .environmentObject(appState)
            .environmentObject(itemRepository)
            .environmentObject(drill)
        #if os(iOS)
            .navigationTitle("Test")
        #endif
    }
}

#endif
