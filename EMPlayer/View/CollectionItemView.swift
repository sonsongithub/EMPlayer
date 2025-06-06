//
//  CollectionItemView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/27.
//

import SwiftUI



struct CollectionItemView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    #if os(iOS)
    let verticalSpacing: CGFloat = 8
    #elseif os(tvOS)
    let verticalSpacing: CGFloat = 4
    #elseif os(macOS)
    let verticalSpacing: CGFloat = 8
    #endif
    let node: ItemNode
    let isFocused: Bool
    
    func itemInfo() -> (BaseItem?, URL?) {
        switch node.item {
        case let .series(item), let .collection(item), let .boxSet(item), let .season(item), let .movie(item), let .episode(item):
            return (item, item.imageURL(server: appState.server))
        default:
            return (nil, nil)
        }
    }
    
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
                        .scaledToFill()
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
            let (item, imageURL) = itemInfo()
            
            Group {
                if let item = item {
                    Button {
                        drill.stack.append(node)
                    } label: {
                        VStack(alignment: .center, spacing: verticalSpacing) {
                            asyncImage(imageURL: imageURL)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.8)
                                .clipped()
                                .cornerRadius(12)
                            Text(item.name)
                                .font(.caption2)
                                .dynamicTypeSize(.xSmall)
                                .lineLimit(2)
                                .background(Color.green)
                            Text(item.overview ?? "")
                                .font(.caption)
                                .dynamicTypeSize(.xSmall)
                                .lineLimit(3)
                                .foregroundStyle(.secondary)
                                .background(Color.purple)
                        }
                    }
                    .buttonStyle(.plain).background(Color.red)
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
