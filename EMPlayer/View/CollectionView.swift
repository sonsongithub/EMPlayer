////
////  CollectionView.swift
////  EMPlayer
////
////  Created by sonson on 2025/02/16.
////

import SwiftUI

#if os(macOS)
#else

//struct VisibleWhenFocusedModifier: ViewModifier {
//    @Environment(\.isFocused) var isFocused
//
//    func body(content: Content) -> some View {
//        content.opacity(isFocused ? 1 : 0)
//    }
//}
//
//extension View {
//    func visibleWhenFocused() -> some View {
//        modifier(VisibleWhenFocusedModifier())
//    }
//}


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
    let id = UUID()
    
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    #if os(iOS)
    let verticalSpacing: CGFloat = 8
    #elseif os(tvOS)
    let verticalSpacing: CGFloat = 32
    #endif
    let node: ItemNode

    @FocusState private var focusedID: UUID?
    
    var body: some View {
        GeometryReader { geometry in
            switch node.item {
            case let .series(item), let .collection(item), let .boxSet(item), let .season(item), let .movie(item), let .episode(item):
                Button {
                    drill.stack.append(node)
                } label: {
                    VStack(alignment: .center, spacing: 0) {
                        if let url = item.imageURL(server: appState.server) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .minimumScaleFactor(.leastNonzeroMagnitude)
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .minimumScaleFactor(.leastNonzeroMagnitude)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .minimumScaleFactor(.leastNonzeroMagnitude)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .minimumScaleFactor(.leastNonzeroMagnitude)
                        }
#if os(iOS)
                        Text(item.name)
                            .font(.headline)
                            .dynamicTypeSize(.xSmall)
                            .lineLimit(2)
#endif
#if os(tvOS)
                        Text(item.name)
                            .font(.caption2)
                            .dynamicTypeSize(.xSmall)
                            .lineLimit(2)
                            .minimumScaleFactor(.leastNonzeroMagnitude)
                            .offset(y: focusedID == id ? 32 : 0) // ← 拡大時に押し出す
                            .animation(.easeInOut(duration: 0.2), value: (focusedID == id))
#endif
                    }
                }
                .minimumScaleFactor(.leastNonzeroMagnitude)
                .scaleEffect(focusedID == id ? 1.0 : 1.0)
//                .shadow(color: .black.opacity(focusedID == id ? 0.3 : 0), radius: focusedID == id ? 10 : 0)
                .animation(.easeInOut(duration: 0.2), value: (focusedID == id))
                .focused($focusedID, equals: id)
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
                    .environmentObject(drill)
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
                                .environmentObject(drill)
                        }
                    }
                }
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
    let drill = DrillDownStore()
    let itemRepository = ItemRepository(authProviding: appState)
    
    let children = (0..<20).map { _ in
        return ItemNode(item: BaseItem.generateRandomItem(type: .series))
    }
    let node = ItemNode(item: BaseItem.generateRandomItem(type: .collectionFolder), children: children)
    
    CollectionView(node: node)
        .environmentObject(appState)
        .environmentObject(itemRepository)
        .environmentObject(drill)
}

#Preview {
    let appState = AppState()
    let baseItem = BaseItem.generateRandomItem(type: .series)
    let itemNode = ItemNode(item: baseItem)
    let drill = DrillDownStore()
    let columnWidth = Double(300)
    let height = floor(columnWidth * 4.0 / 3.0 + 60)
    CollectionItemView(node: itemNode)
        .frame(width: columnWidth, height: height)
        .environmentObject(appState)
        .environmentObject(drill)
#if os(tvOS)
        .buttonStyle(.card)
#endif
}

#endif
