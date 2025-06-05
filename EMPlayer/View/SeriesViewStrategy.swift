//
//  SeriesViewStrategy.swift
//  EMPlayer
//
//  Created by sonson on 2025/06/01.
//

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
    
    enum ScrollDirection {
        case vertical
        case horizontal
    }
    enum EpisodeLayout {
        case portrait
        case landscape
    }

    let scrollDirection: ScrollDirection
    let episodeLayout: EpisodeLayout
    
    let infoViewHeight: CGFloat
    let episodeWidth: CGFloat
    let episodeHeight: CGFloat

    // info view with or without title
    // info view height
    // info view title font
    // info view overview font
    // picker margin top
    // picker margin bottom
    // episode width
    // episode height
    // episode vertical space
    // episode horizontal space
    // episode overview font
    // episode title font
    
    let infoViewHasTitle: Bool
    let infoViewTitleFont: Font
    let infoViewOverviewFont: Font
    let infoViewHorizontalPadding: CGFloat
    let pickerMarginTop: CGFloat
    let pickerMarginBottom: CGFloat
    let episodeVerticalSpace: CGFloat
    let episodeHorizontalSpace: CGFloat
    let episodeOverviewFont: Font
    let episodeTitleFont: Font
    
    let cardContentViewPadding: EdgeInsets
    
    init(isPad: Bool, isPortrait: Bool, size: CGSize) {
        #if os(iOS)
        if isPad {
            scrollDirection = isPortrait ? .vertical : .horizontal
            episodeLayout = isPortrait ? .landscape : .portrait
            if isPortrait {
                infoViewHeight = size.height * 0.3
                episodeWidth = size.width
                episodeHeight = 200
                
                infoViewHorizontalPadding = 30
                
                infoViewHasTitle = false
                infoViewTitleFont = .caption
                infoViewOverviewFont = .body
                pickerMarginTop = 8
                pickerMarginBottom = 8
                episodeVerticalSpace = 0
                episodeHorizontalSpace = 8
                episodeTitleFont = .body
                episodeOverviewFont = .body
                
                cardContentViewPadding = EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 20)
            } else {
                infoViewHeight = size.height * 0.4
                episodeWidth = 400
                episodeHeight = size.height * 0.5
                
                infoViewHorizontalPadding = 30
                
                infoViewHasTitle = false
                infoViewTitleFont = .caption
                infoViewOverviewFont = .headline
                pickerMarginTop = 13
                pickerMarginBottom = 0
                episodeVerticalSpace = 8
                episodeHorizontalSpace = 8
                episodeTitleFont = .body
                episodeOverviewFont = .body
                
                cardContentViewPadding = EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 20)
            }
        } else {
            scrollDirection = isPortrait ? .vertical : .horizontal
            episodeLayout = isPortrait ? .landscape : .landscape
            if isPortrait {
                infoViewHeight = size.height * 0.3
                episodeWidth = size.width
                episodeHeight = 120
                
                infoViewHorizontalPadding = 10
                
                infoViewHasTitle = false
                infoViewTitleFont = .caption
                infoViewOverviewFont = .footnote
                pickerMarginTop = 8
                pickerMarginBottom = 8
                episodeVerticalSpace = 0
                episodeHorizontalSpace = 8
                episodeTitleFont = .caption
                episodeOverviewFont = .footnote
                
                cardContentViewPadding = EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10)
            } else {
                infoViewHeight = size.height * 0.3
                episodeWidth = 600
                episodeHeight = size.height * 0.55
                
                infoViewHorizontalPadding = 10
                
                infoViewHasTitle = false
                infoViewTitleFont = .caption
                infoViewOverviewFont = .footnote
                pickerMarginTop = 8
                pickerMarginBottom = 8
                episodeVerticalSpace = 8
                episodeHorizontalSpace = 8
                episodeTitleFont = .callout
                episodeOverviewFont = .callout
                
                cardContentViewPadding = EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10)
            }
        }
        #else
        scrollDirection = .horizontal
        episodeLayout = .portrait
        infoViewHeight = size.height * 0.4
        episodeWidth = 400
        episodeHeight = size.height * 0.55
        infoViewHasTitle = true
        infoViewTitleFont = .title2
        infoViewOverviewFont = .footnote
        infoViewHorizontalPadding = 10
        pickerMarginTop = 8
        pickerMarginBottom = 8
        episodeVerticalSpace = 8
        episodeHorizontalSpace = 8
        episodeTitleFont = .caption
        episodeOverviewFont = .footnote
        
        cardContentViewPadding = EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 20)
        #endif
    }

    static let `default` = SeriesViewStrategy(isPad: false, isPortrait: true, size: CGSize(width: 1920, height: 800))
    
    static func resolve(using geometry: GeometryProxy) -> SeriesViewStrategy {
        let size = geometry.size
        let isPortrait = size.height >= size.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        return SeriesViewStrategy(isPad: isPad, isPortrait: isPortrait, size: size)
    }
}

#if os(tvOS) || os(iOS)

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
