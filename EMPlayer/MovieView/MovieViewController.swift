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

/// SwiftUI 側で渡す関連動画リストビューの例
struct RelatedVideosView: View {
    var appState: AppState
    let items: [BaseItem]
    var onPush: (BaseItem) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(items, id: \.id) { item in
                    // ← ここを Button に変更
                          Button(action: {
                              onPush(item)
                          }) {
                            VStack(alignment: .leading, spacing: 8) {
                              AsyncImage(url: item.imageURL(server: appState.server)) { img in
                                img.resizable().scaledToFill()
                              } placeholder: {
                                Color.gray.opacity(0.3)
                              }
                              .frame(width: 200, height: 112)
                              .clipped()
                              .cornerRadius(8)
                              .padding(.horizontal, 4)
                              .padding(.vertical, 4)

                              Text(item.name)
                                .font(.footnote)
                                .lineLimit(2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                            .frame(width: 200)
                            .padding(4)
                          }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
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
                self.playerItem?.externalMetadata = createMetadataItems(for: detail)
                self.player?.play()
            }
            
            
        } catch {
            print("Error: \(error)")
            hasError = true
        }
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
                    self.playerItem?.externalMetadata = createMetadataItems(for: detail)
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
