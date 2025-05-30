//
//  SeriesView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/23.
//

import SwiftUI

#if os(tvOS) || os(iOS)

struct EpisodeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @ObservedObject var node: ItemNode
    
    var body: some View {
        if case .episode(_) = node.item {
            Button {
                drill.stack.append(node)
            } label: {
                CardContentView(appState: appState, node: node)
                    .padding([.leading, .top, .bottom], 16)
                    .padding(.trailing, 20)
            }
            .onAppear() {
                Task {
                    await node.updateIfNeeded(using: itemRepository)
                }
            }
        }
    }
}

struct SeasonView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @ObservedObject var node: ItemNode
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(node.children, id: \.id) { item in
                        if case .episode(_) = item.item {
                            EpisodeView(node: item)
                                .environmentObject(appState)
                                .environmentObject(itemRepository)
                                .environmentObject(drill)
                                .frame(width: 800, height: 400)
                        }
                    }
                }.frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
            .scrollClipDisabled()
//            .buttonStyle(.card)
        }
        .onAppear() {
            Task {
                await node.loadChildren(using: itemRepository)
            }
        }
    }
}

struct SeriesInfoView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @ObservedObject var node: ItemNode
    
    var body: some View {
        if case let .series(baseItem) = node.item {
            HStack(alignment: .top, spacing: 10) {
                AsyncImage(url: baseItem.imageURL(server: appState.server)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFit()
                            .clipped()
                            .frame(height:300)
                    case .failure:
                        Color.gray
                    default:
                        Color.gray
                    }
                }
                VStack(alignment: .leading, spacing: 20) {
                    Text(baseItem.name)
                        .font(.caption2)
                        .padding(.leading)
                    Text(baseItem.overview ?? "")
                        .font(.footnote)
                        .padding(.leading)
                }
            }
            .frame(height: 300)
            .padding(30)
        }
    }
}

struct SeriesView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @ObservedObject var node: ItemNode
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                SeriesInfoView(node: node)
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
                    .environmentObject(drill)
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(node.children, id: \.id) { season in
                        if case let .season(base) = season.item {
                            Text(base.name)
                            SeasonView(node: season)
                                .environmentObject(appState)
                                .environmentObject(itemRepository)
                                .environmentObject(drill)
                        }
                    }
                }
                .padding(.top)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear() {
                Task {
                    await node.loadChildren(using: itemRepository)
                }
            }
        }
    }
}

#Preview {
    let appState = AppState()
    let drill = DrillDownStore()
    let itemRepository = ItemRepository(authProviding: appState)
    let seriesNode = ItemNode.dummySeries()
    SeriesView(node: seriesNode)
        .environmentObject(appState)
        .environmentObject(itemRepository)
        .environmentObject(drill)
}

#endif
