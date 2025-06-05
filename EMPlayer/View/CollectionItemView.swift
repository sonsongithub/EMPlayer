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
    func asyncImage(imageURL: URL) -> some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
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
                            if let imageURL = imageURL {
                                asyncImage(imageURL: imageURL)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }

                            Text(item.name)
                                .font(.caption2)
                                .dynamicTypeSize(.xSmall)
                                .lineLimit(2)
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

#Preview {
    let appState = AppState()
    let baseItem = BaseItem.generateRandomItem(type: .series)
    let itemNode = ItemNode(item: baseItem)
    let drill = DrillDownStore()
    let columnWidth = Double(300)
    let height = floor(columnWidth * 4.0 / 3.0 + 60)
    CollectionItemView(node: itemNode   , isFocused: true)
        .frame(width: columnWidth, height: height)
        .environmentObject(appState)
        .environmentObject(drill)
#if os(tvOS)
        .buttonStyle(.plain)
#endif
}
