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

struct SeriesInfoStrategyKey: EnvironmentKey {
    static let defaultValue: SeriesInfoStrategy = .default
}

struct EpisodeContentStrategyKey: EnvironmentKey {
    static let defaultValue: EpisodeContentStrategy = .default
}

extension EnvironmentValues {
    var seriesViewStrategy: SeriesViewStrategy {
        get { self[SeriesViewStrategyKey.self] }
        set { self[SeriesViewStrategyKey.self] = newValue }
    }
    
    var seriesInfoViewStrategy: SeriesInfoStrategy {
        get { self[SeriesInfoStrategyKey.self] }
        set { self[SeriesInfoStrategyKey.self] = newValue }
    }
    
    var episodeViewStrategy: EpisodeContentStrategy {
        get { self[EpisodeContentStrategyKey.self] }
        set { self[EpisodeContentStrategyKey.self] = newValue }
    }
}

struct SeriesInfoStrategy {
    
    let height: CGFloat
    let hasTitle: Bool
    let titleFont: Font
    let overviewFont: Font
    let horizontalPadding: CGFloat
    
    init(parentStrategy: SeriesViewStrategy) {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isPortrait = parentStrategy.screenSize.height >= parentStrategy.screenSize.width
        let size = parentStrategy.screenSize
        
        #if os(iOS)
        if isPad {
            if isPortrait {
                height = size.height * 0.3
                horizontalPadding = 30
                hasTitle = false
                titleFont = .caption
                overviewFont = .body
            } else {
                height = size.height * 0.4
                horizontalPadding = 30
                hasTitle = false
                titleFont = .caption
                overviewFont = .headline
            }
        } else {
            if isPortrait {
                height = size.height * 0.3
                horizontalPadding = 10
                hasTitle = false
                titleFont = .caption
                overviewFont = .footnote
            } else {
                height = size.height * 0.3
                horizontalPadding = 10
                hasTitle = false
                titleFont = .caption
                overviewFont = .footnote
            }
        }
        #else
        height = size.height * 0.4
        hasTitle = true
        titleFont = .title2
        overviewFont = .footnote
        horizontalPadding = 10
        #endif
    }

    static let `default` = SeriesInfoStrategy(parentStrategy: SeriesViewStrategy.default)
    
    static func resolve(using geometry: GeometryProxy) -> SeriesInfoStrategy {
        let size = geometry.size
        let parentStrategy = SeriesViewStrategy(size: size)
        return SeriesInfoStrategy(parentStrategy: parentStrategy)
    }
}

struct EpisodeContentStrategy {
    
    enum ContentLayout {
        case portrait
        case landscape
    }
    
    let contentLayout: ContentLayout

    let screenSize: CGSize
    let isPad: Bool
    
    let width: CGFloat
    let height: CGFloat
    
    let overviewFont: Font
    let titleFont: Font
    let overviewColor: Color
    let titleColor: Color
    
    let padding: EdgeInsets
    
    
    init(parentStrategy: SeriesViewStrategy) {
        isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isPortrait = parentStrategy.screenSize.height >= parentStrategy.screenSize.width
        screenSize = parentStrategy.screenSize
        
        #if os(iOS)
        titleColor = .primary
        overviewColor = .secondary
        if isPad {
            contentLayout = isPortrait ? .landscape : .portrait
            if isPortrait {
                width = screenSize.width
                height = 200
                titleFont = .body
                overviewFont = .body
                padding = EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 20)
            } else {
                width = 400
                height = screenSize.height * 0.5
                titleFont = .body
                overviewFont = .body
                padding = EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 20)
            }
        } else {
            contentLayout = isPortrait ? .landscape : .landscape
            if isPortrait {
                width = screenSize.width
                height = 120
                titleFont = .caption
                overviewFont = .footnote
                padding = EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10)
            } else {
                width = 600
                height = screenSize.height * 0.55
                titleFont = .callout
                overviewFont = .callout
                padding = EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10)
            }
        }
        #else
        contentLayout = .portrait
        width = 400
        height = screenSize.height * 0.45
        titleFont = .caption
        titleColor = .primary
        overviewFont = .caption2
        overviewColor = .secondary
        padding = EdgeInsets(top: 32, leading: 16, bottom: 16, trailing: 20)
        #endif
    }

    static let `default` = EpisodeContentStrategy(parentStrategy: SeriesViewStrategy.default)
    
    static func resolve(using geometry: GeometryProxy) -> EpisodeContentStrategy {
        let size = geometry.size
        let parentStrategy = SeriesViewStrategy(size: size)
        return EpisodeContentStrategy(parentStrategy: parentStrategy)
    }
}

struct SeriesViewStrategy {

    let screenSize: CGSize
    let isPad: Bool
    
    enum ScrollDirection {
        case vertical
        case horizontal
    }
    let scrollDirection: ScrollDirection
    let pickerMarginTop: CGFloat
    let pickerMarginBottom: CGFloat
    let episodeVerticalSpace: CGFloat
    let episodeHorizontalSpace: CGFloat
    let padding: EdgeInsets
    
    init(size: CGSize) {
        isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isPortrait = size.height >= size.width
        screenSize = size
        
        #if os(iOS)
        if isPad {
            scrollDirection = isPortrait ? .vertical : .horizontal
            if isPortrait {
                pickerMarginTop = 8
                pickerMarginBottom = 8
                episodeVerticalSpace = 0
                episodeHorizontalSpace = 8
                
            } else {
                pickerMarginTop = 13
                pickerMarginBottom = 0
                episodeVerticalSpace = 8
                episodeHorizontalSpace = 8
            }
        } else {
            scrollDirection = isPortrait ? .vertical : .horizontal
            if isPortrait {
                pickerMarginTop = 8
                pickerMarginBottom = 8
                episodeVerticalSpace = 0
                episodeHorizontalSpace = 8
            } else {
                pickerMarginTop = 8
                pickerMarginBottom = 8
                episodeVerticalSpace = 8
                episodeHorizontalSpace = 8
            }
        }
        padding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        #else
        scrollDirection = .horizontal
        pickerMarginTop = 8
        pickerMarginBottom = 0
        episodeVerticalSpace = 8
        episodeHorizontalSpace = 0
        padding = EdgeInsets(top: 40, leading: 0, bottom: 40, trailing: 0)
        #endif
    }

    static let `default` = SeriesViewStrategy(size: CGSize(width: 1920, height: 800))
    
    static func resolve(using geometry: GeometryProxy) -> SeriesViewStrategy {
        let size = geometry.size
        return SeriesViewStrategy(size: size)
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
