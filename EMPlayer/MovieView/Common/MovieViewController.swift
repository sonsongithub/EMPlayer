//
//  MovieViewController.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/18.
//

import AVKit
import os
import SwiftUI

func createMetadataItems(for baseItem: BaseItem, seasons: [BaseItem]) -> [AVMetadataItem] {
        
    var mapping: [AVMetadataIdentifier: Any] = [:]
    
    var prefix_title: String? = nil
    
    if let season = seasons.first(where: { $0.name == baseItem.seasonName }) {
        if let seasonNumber = season.indexNumber, let indexNumber = baseItem.indexNumber {
            prefix_title = "SE\(seasonNumber):EP\(indexNumber) " + baseItem.name
        }
    }
    
    if let prefix_title = prefix_title {
        mapping[.iTunesMetadataTrackSubTitle] = prefix_title
    } else {
    }
    
    if let seriessName = baseItem.seriesName {
        mapping[.commonIdentifierTitle] = seriessName
    } else {
        mapping[.commonIdentifierTitle] = baseItem.name
    }
    if let overview = baseItem.overview {
        mapping[.commonIdentifierDescription] = overview
    }
    return mapping.compactMap { createMetadataItem(for:$0, value:$1) }
}

private func createMetadataItem(for identifier: AVMetadataIdentifier,
                                value: Any) -> AVMetadataItem {
    let item = AVMutableMetadataItem()
    item.identifier = identifier
    item.value = value as? NSCopying & NSObjectProtocol
    // Specify "und" to indicate an undefined language.
    item.extendedLanguageTag = "und"
    return item.copy() as! AVMetadataItem
}

final class MovieViewController: PlayerViewModel {
    
    let itemRepository: ItemRepository
    @Published var item: BaseItem
    var sameSeasonItems: [BaseItem] = []
    var seasons: [BaseItem] = []
    
    init(currentItem: BaseItem, appState: AppState, repo: ItemRepository) {
        print("MovieViewController.init()")
        item = currentItem
        self.itemRepository = repo
        super.init(appState: appState)
    }
    
    deinit {
        print("MovieViewController.deinit()")
    }
    
    @MainActor func openNextEpisode() {
        let items = self.sameSeasonItems
        let candidates = items.filter({(item: BaseItem) in
            if let lhsIndex = item.indexNumber, let rhsIndex = self.item.indexNumber {
                return lhsIndex == (rhsIndex + 1)
            }
            return false
        })
        if let item = candidates.first {
            Task {
                await self.playNewVideo(newItem: item)
            }
        }
    }
    
    @MainActor func playNewVideo(newItem: BaseItem) async {
        do {
            let detail = try await itemRepository.detail(of: newItem)
            let (seasons, _) = await loadSameSeasonItems()
            let (server, token, _) = try appState.get()

            guard let url = detail.playableVideo(from: server) else {
                throw APIClientError.invalidURL
            }
            let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["X-Emby-Token": token]])
            DispatchQueue.main.async {
                self.item = detail
                self.player?.pause()
                self.playerItem = AVPlayerItem(asset: asset)
                #if os(tvOS)
                self.seasons = seasons
                self.playerItem?.externalMetadata = createMetadataItems(for: detail, seasons: self.seasons)
                #endif
                self.player?.play()
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    @MainActor
    func postCurrnetPlayTimeOfUserData() {
        var t = 0
        if self.currentTime > 0 {
            t = Int(self.currentTime)
        } else if let player = self.player {
            t = Int(player.currentTime().seconds)
        } else {
            return
        }
        Task {
            do {
                let json = [
                    "PlaybackPositionTicks": t * 10000000
                ]
                let data = try JSONSerialization.data(withJSONObject: json, options: [])
                try await self.itemRepository.putUserData(to: self.item.id, data: data)
            } catch {
                print(error)
            }
        }
    }
    
    @MainActor
    func getSeason(of detail: BaseItem) async throws -> ([BaseItem], [BaseItem]) {
        guard let seriesID = detail.seriesId else { throw ContentError.notFoundSeason }
        
        let parent = try await itemRepository.detail(of: seriesID)
        let seasons = try await itemRepository.children(of: parent)
        for theSeason in seasons {
            let episodes = try await itemRepository.children(of: theSeason)
            let episode_ids = episodes.map { $0.id }
            if episode_ids.contains(detail.id) {
                return (seasons, try await itemRepository.children(of: theSeason))
            }
        }
        throw ContentError.notFoundSeason
    }
    
    func loadMovieOnSimulator() {
        print("simulator")
        let url = Bundle.main.url(forResource: "output01", withExtension: "mp4")!
        let asset = AVURLAsset(url: url)
        DispatchQueue.main.async {
            print("simulator2")
            self.playerItem = AVPlayerItem(asset: asset)
            self.player?.play()
        }
    }
    
    @MainActor
    func setSeekAccrodingToUserData(detail : BaseItem) {
        if let temp = detail.userData?.playbackPositionTicks {
            let s: Double = Double(temp) / 10_000_000.0
            self.player?.seek(to: .init(seconds: s, preferredTimescale: 600))
        }
    }
    
    @MainActor
    func play() async throws {
        let detail = try await itemRepository.detail(of: self.item)
        let (seasons, _) = await loadSameSeasonItems()
        let (server, token, _) = try appState.get()
        guard let url = detail.playableVideo(from: server) else {
            throw APIClientError.invalidURL
        }
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["X-Emby-Token": token]])
        DispatchQueue.main.async {
            self.playerItem = AVPlayerItem(asset: asset)
#if os(tvOS)
            self.seasons = seasons
            self.playerItem?.externalMetadata = createMetadataItems(for: detail, seasons: self.seasons)
#endif
            self.player?.play()
            self.setSeekAccrodingToUserData(detail: detail)
            self.item = detail
        }
    }
    
    func loadSameSeasonItems() async -> ([BaseItem], [BaseItem]) {
        do {
            var (seasons, sameSeasonItems) = try await getSeason(of: self.item)
            for i in 0..<sameSeasonItems.count {
                do {
                    let detail = try await itemRepository.detail(of: sameSeasonItems[i])
                    sameSeasonItems[i] = detail
                } catch {
                    print("Error: \(error)")
                }
            }
            return (seasons, sameSeasonItems)
        } catch {
            print("Error: \(error)")
            return ([], [])
        }
    }
}
