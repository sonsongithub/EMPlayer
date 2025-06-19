//
//  MovieViewController.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/18.
//

import AVKit
import os
import SwiftUI

func createMetadataItems(for baseItem: BaseItem) -> [AVMetadataItem] {
    var mapping: [AVMetadataIdentifier: Any] = [:]
    
    mapping[.commonIdentifierTitle] = baseItem.name
    
    if let seriessName = baseItem.seriesName {
        mapping[.commonIdentifierAlbumName] = seriessName
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
    let appState: AppState
    let itemRepository: ItemRepository
    var item: BaseItem
    var sameSeasonItems: [BaseItem] = []
    
    init(currentItem: BaseItem, appState: AppState, repo: ItemRepository) {
        item = currentItem
        self.appState = appState
        self.itemRepository = repo
        super.init()
    }
    
    @MainActor func playNewVideo(newItem: BaseItem) async {
        do {
            isLoading = true
            let (server, token, _) = try appState.get()
            let detail = try await itemRepository.detail(of: newItem)
            
            
            guard let url = detail.playableVideo(from: server) else {
                throw APIClientError.invalidURL
            }
            let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["X-Emby-Token": token]])
            DispatchQueue.main.async {
                self.playerItem = AVPlayerItem(asset: asset)
                #if os(tvOS)
                self.playerItem?.externalMetadata = createMetadataItems(for: detail)
                #endif
                self.player?.play()
            }
        } catch {
            print("Error: \(error)")
            hasError = true
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
    func getSeason(of detail: BaseItem) async throws -> [BaseItem] {
        guard let seriesID = detail.seriesId else { throw ContentError.notFoundSeason }
        
        let parent = try await itemRepository.detail(of: seriesID)
        let children = try await itemRepository.children(of: parent)
        
        for theSeason in children {
            let episodes = try await itemRepository.children(of: theSeason)
            let episode_ids = episodes.map { $0.id }
            if episode_ids.contains(detail.id) {
                return try await itemRepository.children(of: theSeason)
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

    func updateOwnDetail() async throws {
        let detail = try await itemRepository.detail(of: item)
        self.item = detail
    }
    
    func play() throws {
        let (server, token, _) = try appState.get()
        guard let url = self.item.playableVideo(from: server) else {
            throw APIClientError.invalidURL
        }
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["X-Emby-Token": token]])
        DispatchQueue.main.async {
            self.playerItem = AVPlayerItem(asset: asset)
#if os(tvOS)
            self.playerItem?.externalMetadata = createMetadataItems(for: self.item)
#endif
            self.player?.play()
            self.setSeekAccrodingToUserData(detail: self.item)
        }
    }
    
    func loadSameSeasonItems() async throws -> [BaseItem] {
        var sameSeasonItems = try await getSeason(of: self.item)
        for i in 0..<sameSeasonItems.count {
            do {
                let detail = try await itemRepository.detail(of: sameSeasonItems[i])
                sameSeasonItems[i] = detail
            } catch {
                print("Error: \(error)")
            }
        }
        self.sameSeasonItems = sameSeasonItems
        return sameSeasonItems
    }
}
