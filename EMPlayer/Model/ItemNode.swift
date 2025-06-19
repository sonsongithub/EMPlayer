//
//  ItemNode.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/28.
//

import SwiftUI

enum ItemNodeType: Equatable {
    case root
    case movie(BaseItem)
    case video(BaseItem)
    case musicVideo(BaseItem)
    case episode(BaseItem)
    case series(BaseItem)
    case season(BaseItem)
    case collection(BaseItem)
    case boxSet(BaseItem)
    case unknown
    
    var id: String {
        switch self {
        case .root:
            return "root"
        case .movie(let item),
             .video(let item),
             .musicVideo(let item),
             .episode(let item),
             .series(let item),
             .season(let item),
             .collection(let item),
             .boxSet(let item):
            return item.id
        case .unknown:
            return "unknown-\(UUID().uuidString)"
        }
    }
}

final class ItemNode: ObservableObject, Identifiable, Hashable {
    
    @Published var item: ItemNodeType
    @Published var children: [ItemNode] = []
    @Published var isLoading = false
    @Published var loadError: Error? = nil
    @Published var selected: Bool = false
    @Published var apectRatio: Double? = nil
    
    let uuid = UUID()
    
    init(item: BaseItem?) {
        if let base = item {
            self.item = ItemNode.wrap(baseItem: base)
        } else {
            self.item = .root
        }
    }
    
    init(item: BaseItem?, children: [ItemNode] = []) {
        if let base = item {
            self.item = ItemNode.wrap(baseItem: base)
            self.children = children
        } else {
            self.item = .root
            self.children = children
        }
    }
    
    init(nodeType: ItemNodeType, children: [ItemNode] = []) {
        self.item = nodeType
        self.children = children
    }

    var baseItem: BaseItem? {
        switch item {
        case .movie(let b), .video(let b), .musicVideo(let b), .episode(let b),
             .series(let b), .season(let b), .collection(let b), .boxSet(let b):
            return b
        default:
            return nil
        }
    }

    var customID: String {
        item.id
    }

    static func wrap(baseItem: BaseItem) -> ItemNodeType {
        switch baseItem.type {
        case .video:           return .video(baseItem)
        case .movie:           return .movie(baseItem)
        case .musicVideo:      return .musicVideo(baseItem)
        case .series:          return .series(baseItem)
        case .episode:         return .episode(baseItem)
        case .season:          return .season(baseItem)
        case .boxSet:          return .boxSet(baseItem)
        case .collectionFolder:return .collection(baseItem)
        default:               return .unknown
        }
    }

    // MARK: - 非同期データロード処理

    @MainActor
    func loadChildren(using repository: ItemRepository) async {
        guard let baseItem = self.baseItem else { return }
        isLoading = true
        loadError = nil
        
        do {
            if self.children.isEmpty {
                let rawChildren = try await repository.children(of: baseItem)
                self.children = rawChildren.map { ItemNode(nodeType: ItemNode.wrap(baseItem: $0)) }
            }
            // 子要素に詳細データを読み込む（オプション）
            for i in 0..<children.count {
                await children[i].updateWithDetail(using: repository)
            }
        } catch {
            loadError = error
        }

        isLoading = false
    }

    @MainActor
    func updateWithDetail(using repository: ItemRepository) async {
        guard let baseItem = self.baseItem else { return }
        do {
            let detailed = try await repository.detail(of: baseItem)
            self.item = ItemNode.wrap(baseItem: detailed)
        } catch {
            self.loadError = error
        }
    }

    // MARK: - Identifiable / Hashable

    static func == (lhs: ItemNode, rhs: ItemNode) -> Bool {
        lhs.customID == rhs.customID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(customID)
    }

    // MARK: - 表示用

    func display() -> String {
        switch self.item {
        case .root:              return "Root"
        case .movie(let b), .series(let b), .season(let b),
             .episode(let b), .collection(let b), .boxSet(let b),
             .musicVideo(let b): return b.name
        default:                 return "Unknown"
        }
    }
}

extension ItemNode {
    static func dummySeries() -> ItemNode {
        let series = BaseItem.createSeriesData()

        let seriesNode = ItemNode(item: series)

        let seasons = BaseItem.createSeasonData(series: series)

        let seasonNodes = seasons.map { ItemNode(item: $0) }

        for i in 0..<seasonNodes.count {
            let episodes = BaseItem.createEpisodeData(season: seasons[i])
            let episodeNodes = episodes.map { ItemNode(item: $0) }
            seasonNodes[i].children = episodeNodes
        }

        seriesNode.children = seasonNodes

        print(seriesNode)

        for node in seriesNode.children {
            print("Season: \(node.display())")
            for episode in node.children {
                print("  Episode: \(episode.display())")
            }
        }

        return seriesNode
    }

    static func dummyCollection() -> ItemNode {
        let series_array = [
            dummySeries(),
            dummySeries(),
            dummySeries(),
            dummySeries()
        ]
        let item = BaseItem(name: "ダミーコレクション",
                        originalTitle: nil,
                        id: UUID().uuidString,
                        sourceType: nil,
                        hasSubtitle: nil,
                        path: nil,
                        overview: "to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. to be written. ",
                        aspectRatio: nil,
                        isHD: nil,
                        seriesId: nil,
                        seriesName: nil,
                        seasonName: nil,
                        width: nil,
                        height: nil,
                        mediaSource: nil,
                        mediaStreams: nil,
                        indexNumber: nil,
                        isFolder: nil,
                        type: .boxSet,
                        userData: nil,
                        imageTags: nil,
                        collectionType: nil)
        return ItemNode(item: item, children: series_array)
    }
    
    @MainActor
    func updateIfNeeded(using repository: ItemRepository) async {
        guard let base = self.baseItem else { return }

        if base.overview == nil || base.imageTags == nil {
            do {
                let detailed = try await repository.detail(of: base)
                self.item = ItemNode.wrap(baseItem: detailed)
            } catch {
                self.loadError = error
            }
        }
    }
    
    @MainActor
    func loadChildren(using repository: ItemRepository, reload: Bool = false) async {
        guard let baseItem = self.baseItem else { return }

        if !reload && !children.isEmpty {
            return  // すでにロード済み
        }

        isLoading = true
        loadError = nil

        do {
            let rawChildren = try await repository.children(of: baseItem)
            self.children = rawChildren.map { ItemNode(nodeType: ItemNode.wrap(baseItem: $0)) }

            // オプション：詳細取得はView側に任せる場合は省略可能
        } catch {
            loadError = error
        }

        isLoading = false
    }
}

