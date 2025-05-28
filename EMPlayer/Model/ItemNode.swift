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

    let item: ItemNodeType
    let uuid = UUID()
    @Published var children: [ItemNode]
    @Published var isLoading = false
    @Published var loadError: Error? = nil
    @Published var selected: Bool = false
    
    var customID: String {
        return item.id
    }
    
    init(item: BaseItem?, children: [ItemNode]? = nil) {
        self.children = children ?? []
        guard let item = item else {
            self.item = .root
            return
        }
        
        switch item.type {
        case .video:
            self.item = .video(item)
        case .movie:
            self.item = .movie(item)
        case .musicVideo:
            self.item = .musicVideo(item)
        case .series:
            self.item = .series(item)
        case .episode:
            self.item = .episode(item)
        case .season:
            self.item = .season(item)
        case .boxSet:
            self.item = .boxSet(item)
        case .collectionFolder:
            self.item = .collection(item)
        default:
            self.item = .unknown
        }
    }
    
    static func == (lhs: ItemNode, rhs: ItemNode) -> Bool {
        lhs.customID == rhs.customID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(customID)
    }
    
    func display() -> String {
        switch self.item {
        case .root:               return "Root"
        case .movie(let b):       return b.name
        case .series(let b):      return b.name
        case .season(let b):      return b.name
        case .episode(let b):     return b.name
        case .collection(let b):  return b.name
        case .boxSet(let b):       return b.name
        case .musicVideo(let b):  return b.name
        default:               return "Unknown"
        }
    }
    
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
}
