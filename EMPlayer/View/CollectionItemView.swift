//
//  CollectionItemView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/27.
//

#if os(tvOS) || os(iOS)

import SwiftUI

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
