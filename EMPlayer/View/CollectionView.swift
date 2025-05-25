////
////  CollectionView.swift
////  EMPlayer
////
////  Created by sonson on 2025/02/16.
////

import SwiftUI

#if os(macOS)
#else

@ViewBuilder
private func viewForItemNode(node: ItemNode, appState: AppState, itemRepository: ItemRepository) -> some View {
        switch node.item {
        case .collection(_):
            CollectionView(node: node)
        case .series(_):
            CollectionView(node: node)
        case .boxSet(_):
            CollectionView(node: node)
        case .season(_):
            ItemNodeView(node: node)
        case .movie(let base), .episode(let base):
            MovieView(item: base,
                         appState: appState,
                         itemRepository: itemRepository) {
                appState.playingItem = nil
            }
        default:
            Text("error")
        }
}

struct CollectionItemView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    #if os(iOS)
    let verticalSpacing: CGFloat = 8
    #elseif os(tvOS)
    let verticalSpacing: CGFloat = 32
    #endif
    let node: ItemNode

    var body: some View {
        GeometryReader { geometry in
            switch node.item {
            case let .series(item), let .collection(item), let .boxSet(item), let .season(item), let .movie(item), let .episode(item):
                
//                if case let .series(item) = node.item || let .collection(item) = node.item {
                    NavigationLink(value: node) {
                        VStack(alignment: .center, spacing: verticalSpacing) {
                            if let url = item.imageURL(server: appState.server) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                        #if os(tvOS)
                                            .aspectRatio(geometry.size.width / geometry.size.height, contentMode: .fill)
                                        #endif
                                        #if os(iOS)
                                            .aspectRatio(geometry.size.width / geometry.size.height, contentMode: .fill)
//                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .cornerRadius(8)
                                        #endif
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .foregroundColor(.gray)
                            }
                            #if os(iOS)
                            Text(item.name)
                                .font(.headline)
                                .dynamicTypeSize(.xSmall)
                                .lineLimit(2)
                                .background(Color.red.opacity(0.1))
                            #endif
                            #if os(tvOS)
                            Text(item.name)
                                .font(.caption2)
                                .dynamicTypeSize(.xSmall)
                                .lineLimit(2)
                                .frame(height: 60)
                            #endif
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderless)
                
            default:
                Text("Unknown")
            }
        }
    }
}

struct RowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    let items: [ItemNode]
    let width: CGFloat
    let height: CGFloat
    let horizontalSpacing: CGFloat
    var body: some View {
        HStack(spacing: horizontalSpacing) {
            ForEach(items, id: \.id) { item in
                CollectionItemView(node: item)
                    .frame(width: width, height: height)
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
            }
        }
        .padding()
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

struct CollectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @ObservedObject var node: ItemNode
    
    #if os(iOS)
    let minWidth: CGFloat = 60  // カラムの最小幅
    let maxWidth: CGFloat = 150  // カラムの最大幅
    let horizontalSpacing: CGFloat = 32
    let itemPerRow: CGFloat = 8
    let space: CGFloat = 8
    #elseif os(tvOS)
    let minWidth: CGFloat = 100  // カラムの最小幅
    let maxWidth: CGFloat = 320  // カラムの最大幅
    let horizontalSpacing: CGFloat = 64
    let itemPerRow: CGFloat = 7
    let space: CGFloat = 64
    #endif
    var body: some View {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let itemPerRow = max(1, Int(availableWidth / maxWidth))
                let columnWidth = max(minWidth, (availableWidth - (horizontalSpacing * CGFloat(itemPerRow + 1))) / CGFloat(itemPerRow))
                let height = floor(columnWidth * 4 / 3.0 + 60)
                ScrollView {
                    VStack(alignment: .leading, spacing: space) {
                        let rows = self.node.children.chunked(into: itemPerRow)
                        ForEach(rows.indices, id: \.self) { rowIndex in
                            RowView(items: rows[rowIndex], width: columnWidth, height: height, horizontalSpacing: horizontalSpacing)
                                .environmentObject(appState)
                                .environmentObject(itemRepository)
                        }
                        Spacer()
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                Task {
                    switch node.item {
                    case let .collection(base), let .series(base), let .boxSet(base), let .season(base):
                        Task {
                            let items = try await self.itemRepository.children(of: base)
                            print("items: \(items.count)")
                            let children = items.map({ ItemNode(item: $0)})
                            DispatchQueue.main.async {
                                node.children = children
                                print("node.children: \(node.children.count)")
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
    let itemRepository = ItemRepository(authProviding: appState)
    
    let children = (0..<20).map { _ in
        return ItemNode(item: BaseItem.generateRandomItem(type: .series))
    }
    let node = ItemNode(item: BaseItem.generateRandomItem(type: .collectionFolder), children: children)
    
    CollectionView(node: node)
        .environmentObject(appState)
        .environmentObject(itemRepository)
}

#Preview {
    let appState = AppState()
    let baseItem = BaseItem.generateRandomItem(type: .series)
    let itemNode = ItemNode(item: baseItem)
    let columnWidth = Double(300)
    let height = floor(columnWidth * 4.0 / 3.0 + 60)
    CollectionItemView(node: itemNode)
        .frame(width: columnWidth, height: height)
        .environmentObject(appState)
        .background(Color.gray.opacity(0.6))
}

#endif
