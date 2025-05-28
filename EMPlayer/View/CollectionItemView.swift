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
        switch itemInfo() {
        case let (.some(item), .some(imageURL)):
            Button {
                drill.stack.append(node)
            } label: {
                VStack(alignment: .center, spacing: verticalSpacing) {
                    asyncImage(imageURL: imageURL)
                    Text(item.name)
                        .font(.caption2)
                        .dynamicTypeSize(.xSmall)
                        .lineLimit(2)
                }
            }.buttonStyle(.plain)
        case let (.some(item), _):
            Button {
                drill.stack.append(node)
            } label: {
                VStack(alignment: .center, spacing: verticalSpacing) {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                    Text(item.name)
                        .font(.caption2)
                        .dynamicTypeSize(.xSmall)
                        .lineLimit(2)
                }
            }.buttonStyle(.plain)
        default:
            Text("Unknown item type")
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
    CollectionItemView(node: itemNode, isFocused: true)
        .frame(width: columnWidth, height: height)
        .environmentObject(appState)
        .environmentObject(drill)
#if os(tvOS)
        .buttonStyle(.plain)
#endif
}
