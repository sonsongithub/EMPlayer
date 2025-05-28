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
    
    let node: ItemNode
    
    var body: some View {
        if case let .episode(base) = node.item {
            Button {
                print("a")
            } label: {
                VStack(alignment: .leading) {
                    Text(base.name)
                        .font(.caption)
                        .padding(.bottom, 5)
                    AsyncImage(url: base.imageURL(server: appState.server)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Color.gray
                                .frame(height: 200)
                        default:
                            Color.gray
                                .frame(height: 200)
                        }
                    }
                    Text(base.overview ?? "")
                        .font(.body)
                        .padding(.top, 5)
                }
            }
            .buttonStyle(.plain)
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
                HStack {
                    ForEach(node.children, id: \.id) { item in
                        if case .episode(_) = item.item {
                            EpisodeView(node: item)
                                .environmentObject(appState)
                                .environmentObject(itemRepository)
                                .environmentObject(drill)
                                .frame(width: 450, height: 350)
                        }
                    }
                }.frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }.onAppear() {
            switch node.item {
            case let .collection(base), let .series(base), let .boxSet(base), let .season(base):
                Task {
                    let items = try await self.itemRepository.children(of: base)
                    print("items: \(items.count)")
                    let children = items.map({ ItemNode(item: $0)})
                    DispatchQueue.main.async {
                        node.children = children
                        
                        Task {
                            for i in 0..<children.count {
                                if case let .episode(base) = children[i].item {
                                    let detail = try await itemRepository.detail(of: base)
                                    node.children[i] = ItemNode(item: detail)
                                }
                            }
                            
                        }
                    }
                }
            default:
                do {}
            }
        }
    }
}

struct SeriesInfoView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    let baseItem: BaseItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(url: baseItem.imageURL(server: appState.server)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipped()
                case .failure:
                    Color.gray
                        .frame(height: 200)
                default:
                    Color.gray
                        .frame(height: 200)
                }
            }
            VStack(alignment: .leading, spacing: 20) {
                Text(baseItem.name)
                    .font(.title)
                    .padding(.leading)
                Text(baseItem.overview ?? "")
                    .font(.body)
                    .padding(.leading)
            }
        }
        .padding(30)
        .background(Color.gray)
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
                if case let .series(base) = node.item {
                    SeriesInfoView(baseItem: base)
                        .environmentObject(appState)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                }
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
                switch node.item {
                case let .collection(base), let .series(base), let .boxSet(base), let .season(base):
                    Task {
                        let items = try await self.itemRepository.children(of: base)
                        print("items: \(items.count)")
                        let children = items.map({ ItemNode(item: $0)})
                        DispatchQueue.main.async {
                            node.children = children
                            
                            Task {
                                for i in 0..<children.count {
                                    if case let .episode(base) = children[i].item {
                                        let detail = try await itemRepository.detail(of: base)
                                        node.children[i] = ItemNode(item: detail)
                                    }
                                }
                                
                            }
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
    let seriesNode = ItemNode.dummySeries()
    SeriesView(node: seriesNode)
        .environmentObject(appState)
        .environmentObject(itemRepository)
        .environmentObject(drill)
}

#endif
