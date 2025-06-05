//
//  CardContentView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/29.
//

import AVKit
import os
import SwiftUI

struct CardContentView: View {
    
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
                                Text("\(index). \(item.name)")
                                    .font(strategy.episodeTitleFont)
                                    .lineLimit(1)
                                    .padding(.bottom, 10)
                                    .frame(alignment: .leading)
                                    .foregroundColor(.black)
                            } else {
                                Text(item.name)
                                    .font(strategy.episodeTitleFont)
                                    .lineLimit(2)
                                    .frame(alignment: .leading)
                                    .foregroundColor(.black)
                            }
                            Text(item.overview ?? "")
                                .font(strategy.episodeTitleFont)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.black)
                            Spacer(minLength: 0)
                        }
                    }
                case .portrait:
                    VStack(alignment: .leading) {
                        AsyncImage(url: item.imageURL(server: appState.server)) { img in
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .clipped()
                                .frame(width: geometry.size.width * 1.0)
                                .lineLimit(2)
                        } placeholder: {
                            Color.white.opacity(0.6)
                        }
                        if let index = item.indexNumber {
                            Text("\(index). \(item.name)")
                                .font(strategy.episodeTitleFont)
                                .lineLimit(3)
                        } else {
                            Text(item.name)
                                .font(strategy.episodeTitleFont)
                                .lineLimit(3)
                        }
                        Text(item.overview ?? "")
                            .font(strategy.episodeOverviewFont)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                        Spacer(minLength: 0)
                    }
                }
            } else {
                Text("Error")
            }
        }
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
