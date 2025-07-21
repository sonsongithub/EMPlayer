//
//  CollectionView.swift
//  EMPlayer
//
//  Created by sonson on 2025/06/14.
//

#if os(tvOS) || os(iOS)

import SwiftUI

extension Notification.Name {
    static let collectionViewShouldRefresh = Notification.Name("collectionViewShouldRefresh")
}

struct CollectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @ObservedObject var node: ItemNode
    @Environment(\.collectionViewStrategy) var strategy
    
    @FocusState private var focusedID: UUID?
    
    @State private var lastFocusedID: UUID?
    
    @State private var currentOpacity: Double = 1.0 // デフォルトは完全に表示
    
    var isSearchView = false
    @Environment(\.scenePhase) var scenePhase // このまま残しておく
    
    var body: some View {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let spacing = 80.0
                let itemPerRowPortrait = strategy.itemsPerRow
                let columnWidthPortrait = (availableWidth - spacing * CGFloat(itemPerRowPortrait + 1)) / CGFloat(itemPerRowPortrait)
                let heightPortrait = floor(columnWidthPortrait * strategy.itemAspectRatio)
                let columnsPortrait = Array(repeating: GridItem(.fixed(columnWidthPortrait), spacing: spacing), count: itemPerRowPortrait)

                let itemPerRowLandscape = 4
                let spacingLandscape: CGFloat = 60.0
                let columnWidthLandscape = (availableWidth - spacingLandscape * CGFloat(itemPerRowLandscape + 1)) / CGFloat(itemPerRowLandscape)
                let heightLandscape = floor(columnWidthLandscape / 4.0 * 3.0)
                let columnsLandscape = Array(repeating: GridItem(.fixed(columnWidthLandscape), spacing: spacingLandscape), count: itemPerRowLandscape)

                ScrollViewReader { proxy in
                    ScrollView {
                        if let baseItem = node.baseItem {
                            Text(baseItem.name)
                                .font(.title2)
                                .padding()
                        }
                        LazyVGrid(columns: columnsPortrait, alignment: .leading, spacing: strategy.verticalSpacing) {
                            ForEach(node.items(of: [.series, .movie, .season]), id: \.id) { item in
                                CollectionItemView(node: item, isFocused: (focusedID == item.uuid))
                                    .frame(width: columnWidthPortrait, height: heightPortrait)
                                    .focused($focusedID, equals: item.uuid)
                                    .zIndex(focusedID == item.uuid ? 1 : 0)
                                    .environment(\.collectionItemStrategy, CollectionItemStrategy.createFrom(parent: strategy))
                                    .id(item.uuid)
                            }
                        }
                        .padding(.top, isSearchView ? 100 : 0)
                        .padding(.horizontal, spacing)

                        LazyVGrid(columns: columnsLandscape, alignment: .leading, spacing: 45.0) {
                            ForEach(node.items(of: [.boxSet, .episode, .video, .musicVideo]), id: \.id) { item in
                                CollectionLandscapeItemView(node: item, isFocused: (focusedID == item.uuid))
                                    .frame(width: columnWidthLandscape, height: heightLandscape)
                                    .focused($focusedID, equals: item.uuid)
                                    .zIndex(focusedID == item.uuid ? 1 : 0)
                                    .environment(\.collectionItemStrategy, CollectionItemStrategy.createFrom(parent: strategy))
                                    .id(item.uuid)
                            }
                        }
                        .padding(.top, 50)
                        .padding(.horizontal, spacing)
                    }
                    .onDisappear() {
                        print("CollectionView disappeared")
                        drill.lastFocusedItemID = nil
                    }
                    .onChange(of: focusedID) {
                        // ユーザーがリモコンでフォーカスを動かしたときにスクロール
                        if let focusedID = focusedID {
                            print("CollectionView focusedID changed to: \(focusedID)")
                            proxy.scrollTo(focusedID, anchor: .center)
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .collectionViewShouldRefresh)) { _ in
                        self.currentOpacity = 0.0
                        if let savedID = drill.lastFocusedItemID {
                            print("Attempting to restore focus to \(savedID) from DrillDownStore.")
                            // 非常に重要: UI スレッドで、View の描画が完了した後に実行
                            // 複数回試すことで、成功率を高める
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // 最初の試行
                                self.focusedID = savedID
                                proxy.scrollTo(savedID, anchor: .center)
                                print("1st attempt: Focus and scroll applied for: \(savedID)")
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // 2回目の試行
                                self.focusedID = savedID
                                proxy.scrollTo(savedID, anchor: .center)
                                print("2nd attempt: Focus and scroll applied for: \(savedID)")
                            }
                        }
                        // 画面を徐々に明るくするアニメーション
                        withAnimation(.easeIn(duration: 0.5)) { // 0.5秒かけてフェードイン
                            self.currentOpacity = 1.0
                        }
                    }
                    .onAppear {
                        print("CollectionView appeared")
                        Task {
                            if node.children.isEmpty {
                                await node.loadChildren(using: itemRepository, reload: false)
                            }
                        }
                    }
                }
            }.opacity(currentOpacity) // ここで全体の不透明度を制御
        }
}

#Preview {
//    @Previewable @State var shouldRefresh = false
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
//        .frame(width: 1920, height: 1080)
}

#endif
