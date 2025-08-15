//
//  CardContentView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/29.
//

#if os(tvOS) || os(iOS)

import AVKit
import os
import SwiftUI

struct EpisodeContent: View {
    
    enum Orientation {
        case portrait
        case landscape
    }
    
    let appState: AppState
    
    @Environment(\.seriesViewStrategy) var strategy
    
    @ObservedObject var node: ItemNode
    let id: UUID
    let rotation: Orientation

    var body: some View {
        GeometryReader { geometry in
            
            if let item = node.baseItem {
                switch rotation {
                case .landscape:
                    HStack(alignment: .top, spacing: 10) {
                        AsyncImage(url: item.imageURL(server: appState.server)) { img in
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(2)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            if let index = item.indexNumber {
                                HStack {
                                    Text("Episode \(index)")
                                        .font(strategy.episode.titleFont)
                                        .foregroundColor(strategy.episode.titleColor)
                                        .lineLimit(3)
                                        .frame(width: .infinity, alignment: .leading)
                                }
                            }
                            HStack {
                                Text("\(item.name)")
                                    .font(strategy.episode.titleFont)
                                    .foregroundColor(strategy.episode.titleColor)
                                    .lineLimit(3)
                                    .frame(width: .infinity, alignment: .trailing)
                            }
                            if let runTime = item.runtimeTicks {
                                let durationInMinutes = Int(runTime / 10_000_000 / 60)
                                HStack {
                                    Spacer()
                                    Text("\(durationInMinutes) min")
                                        .font(strategy.episode.titleFont)
                                        .foregroundColor(strategy.episode.titleColor)
                                        .lineLimit(3)
                                        .frame(width: .infinity, alignment: .trailing)
                                }
                            }
                            
                            Text(item.overview ?? "")
                                .font(strategy.episode.overviewFont)
                                .foregroundColor(strategy.episode.overviewColor)
                                .lineLimit(12)
                        }
                    }
                case .portrait:
                    VStack(alignment: .leading) {
                        AsyncImage(url: item.imageURL(server: appState.server)) { img in
                            img
                                .resizable()
                                .aspectRatio(contentMode: strategy.episode.width > strategy.episode.height ? .fill : .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .clipped()
                                .frame(width: geometry.size.width * 1.0)
                                .lineLimit(2)
                        } placeholder: {
                            Color.white.opacity(0.6)
                        }
                        
                        
                        if let index = item.indexNumber {
                            HStack {
                                Text("Episode \(index)")
                                    .font(strategy.episode.titleFont)
                                    .foregroundColor(strategy.episode.titleColor)
                                    .lineLimit(1)
                                    .frame(width: .infinity, alignment: .leading)
                            }
                        }
                        HStack {
                            Text("\(item.name)")
                                .font(strategy.episode.titleFont)
                                .foregroundColor(strategy.episode.titleColor)
                                .lineLimit(1)
                                .frame(width: .infinity, alignment: .trailing)
                        }
                        if let runTime = item.runtimeTicks {
                            let durationInMinutes = Int(runTime / 10_000_000 / 60)
                            HStack {
                                Spacer()
                                Text("\(durationInMinutes) min")
                                    .font(strategy.episode.titleFont)
                                    .foregroundColor(strategy.episode.titleColor)
                                    .lineLimit(1)
                                    .frame(width: .infinity, alignment: .trailing)
                            }
                        }
                        
                        Text(item.overview ?? "")
                            .font(strategy.episode.overviewFont)
                            .foregroundColor(strategy.episode.overviewColor)
                            .lineLimit(strategy.episode.overviewLineLimit)
                    }
                }
            } else {
                Text("Error")
            }
        }
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
            .navigationTitle("a")
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#endif
