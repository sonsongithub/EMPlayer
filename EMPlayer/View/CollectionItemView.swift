//
//  CollectionItemView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/27.
//

#if os(tvOS) || os(iOS)

import SwiftUI

struct CollectionLandscapeItemView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @Environment(\.collectionItemStrategy) var strategy
    
    @ObservedObject var node: ItemNode
    let isFocused: Bool
    
    
    @ViewBuilder
    func asyncImage(imageURL: URL?) -> some View {
        if let imageURL = imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                @unknown default:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                }
            }
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
        }
    }
    
    func seasonInfo(item: BaseItem) -> String? {
        if let seasonName = item.seasonName, let index = item.indexNumber {
            return "\(seasonName):EP\(index)"
        }
        return nil
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            Group {
                if let item = node.baseItem {
                    Button {
                        drill.stack.append(node)
                        drill.lastFocusedItemID = node.uuid
                        print("Focus on item: \(item.name) with ID: \(node.uuid)")
                    } label: {
                        VStack(alignment: .center, spacing: strategy.verticalSpacing) {
                            asyncImage(imageURL: item.imageURL(server: appState.server))
                                .frame(width: geometry.size.width, height: geometry.size.height * strategy.ratioOfTeaserToHeight)
                                .clipped()
                                .cornerRadius(8)
                            if let text = seasonInfo(item: item) {
                                Text(text)
                                    .font(strategy.titleFont)
                                    .lineLimit(1)
                            }
                            Text(item.name)
                                .font(.caption)
                                .lineLimit(strategy.titleLineLimit)
                                .padding(strategy.titlePadding)
                                .foregroundColor(strategy.titleColor)
                            if let overview = item.overview {
                                Text(overview)
                                    .font(strategy.overviewFont)
                                    .padding(strategy.overviewPadding)
                                    .foregroundColor(strategy.overviewColor)
                                    .lineLimit(10)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Unknown item type")
                }
            }
            .onAppear {
                Task {
                    await node.updateIfNeeded(using: itemRepository)
                }
            }
        }
    }
}

struct CollectionItemView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @Environment(\.collectionItemStrategy) var strategy
    @ObservedObject var node: ItemNode
    let isFocused: Bool
    
    enum ImageAspectRatio {
        case fill
        case fit
        case none
    }
    
    func itemInfo() -> (BaseItem?, URL?, ImageAspectRatio) {
        switch node.item {
        case let .series(item), let .season(item), let .movie(item):
            return (item, item.imageURL(server: appState.server), .fill)
        case let .collection(item), let .boxSet(item), let .episode(item), let .musicVideo(item):
            return (item, item.imageURL(server: appState.server), .fit)
        default:
            return (nil, nil, .none)
        }
    }
    
    @ViewBuilder
    func asyncImage(imageURL: URL?, aspectRatio: ImageAspectRatio) -> some View {
        if let imageURL = imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    if aspectRatio == .fit {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                @unknown default:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                }
            }
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let (item, imageURL, aspectRatio) = itemInfo()
            Group {
                if let item = item {
                    Button {
                        drill.stack.append(node)
                        drill.lastFocusedItemID = node.uuid
                    } label: {
                        VStack(alignment: .center, spacing: strategy.verticalSpacing) {
                            asyncImage(imageURL: imageURL, aspectRatio: aspectRatio)
                                .frame(width: geometry.size.width, height: geometry.size.height * strategy.ratioOfTeaserToHeight)
                                .clipped()
                                .cornerRadius(8)
                            Text(item.name)
                                .font(strategy.titleFont)
                                .lineLimit(strategy.titleLineLimit)
                                .padding(strategy.titlePadding)
                                .foregroundColor(strategy.titleColor)
                            Text(item.overview ?? "")
                                .font(strategy.overviewFont)
                                .padding(strategy.overviewPadding)
                                .foregroundColor(strategy.overviewColor)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                    Text("Unknown item type")
                    Spacer()
                }
            }
            .onAppear {
                Task {
                    await node.updateIfNeeded(using: itemRepository)
                }
            }
        }
    }
}


#Preview {
    let appState = AppState()
    let drill = DrillDownStore()
    let itemRepository = ItemRepository(authProviding: appState)
    
    let children1 = (0..<20).map { _ in
        return ItemNode(item: BaseItem.generateRandomItem(type: .movie))
    }
    let children2 = (0..<20).map { _ in
        return ItemNode(item: BaseItem.generateRandomItem(type: .boxSet))
    }
    let children3 = children1 + children2
    let node = ItemNode(item: BaseItem.generateRandomItem(type: .collectionFolder), children: children3)
    
    CollectionView(node: node)
        .environmentObject(appState)
        .environmentObject(itemRepository)
        .environmentObject(drill)
}

#endif
