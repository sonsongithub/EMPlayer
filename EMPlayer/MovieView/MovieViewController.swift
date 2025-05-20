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
    func getSeason(of item: BaseItem) async throws -> [BaseItem] {
        let detail = try await itemRepository.detail(of: item)
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
        
    @MainActor func fetch() async {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            Task {
                print("simulator")
                let url = Bundle.main.url(forResource: "output01", withExtension: "mp4")!
                let asset = AVURLAsset(url: url)
                DispatchQueue.main.async {
                    print("simulator2")
                    self.playerItem = AVPlayerItem(asset: asset)
                    self.player?.play()
                }
            }
        } else {
            do {
                isLoading = true
                let (server, token, _) = try appState.get()
                let detail = try await itemRepository.detail(of: item)
                
                
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
            isLoading = false
        }
    }
}
