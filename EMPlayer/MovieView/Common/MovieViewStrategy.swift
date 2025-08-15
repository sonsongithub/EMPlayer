//
//  MovieViewStrategy.swift
//  EMPlayer
//
//  Created by sonson on 2025/06/21.
//

import SwiftUI

#if os(iOS)

struct MovieViewStrategyKey: EnvironmentKey {
    static let defaultValue: MovieViewStrategy = .default
}

extension EnvironmentValues {
    var movieViewStrategy: MovieViewStrategy {
        get { self[MovieViewStrategyKey.self] }
        set { self[MovieViewStrategyKey.self] = newValue }
    }
}

struct MovieViewStrategy {
    let isPad: Bool
    let isPortrait: Bool
    
    init(screenSize: CGSize) {
        isPortrait = screenSize.height >= screenSize.width
        isPad = UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static let `default` = MovieViewStrategy(screenSize: CGSize(width: 375, height: 667))
    
    static func resolve(using geometry: GeometryProxy) -> MovieViewStrategy {
        let size = geometry.size
        return MovieViewStrategy(screenSize: size)
    }
}

#endif
