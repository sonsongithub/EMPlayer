//
//  MovietvOSView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/18.
//


import AVKit
import SwiftUI

struct MovietvOSView: View {
    @StateObject private var viewController: MovieViewController
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository

    /// ここでホスティングコントローラを @State で保持
    @State private var infoVCs: [UIViewController] = []

    var onClose: () -> Void

    init(item: BaseItem, appState: AppState, itemRepository: ItemRepository, onClose: @escaping ()->Void = {}) {
        _viewController = .init(wrappedValue: MovieViewController(currentItem: item, appState: appState, repo: itemRepository))
        self.onClose = onClose
    }

    var body: some View {
        // -- もしくは直接 --
        CustomVideoPlayerView(playerViewModel: viewController, onClose: onClose, customInfoControllers: infoVCs)
        .ignoresSafeArea()
        .onAppear {
            Task {
                await viewController.fetch()
                
                do {
                    let detail = try await itemRepository.detail(of: viewController.item)
                    print(detail)
                    if let seriesID = detail.seriesId {
                        let parent = try await itemRepository.detail(of: seriesID)
                        let children = try await itemRepository.children(of: parent)
                        print(seriesID)
                        print(parent)
                        print(children)
                        
                        for theSeason in children {
                            let episodes = try await itemRepository.children(of: theSeason)
                            let episode_ids = episodes.map { $0.id }
                            if episode_ids.contains(detail.id) {
                                let related = try await itemRepository.children(of: theSeason)
                                DispatchQueue.main.async {
                                    let view = RelatedVideosView(appState: self.appState, items: related)
                                    let vc = UIHostingController(rootView: view)
                                    vc.title = "test"
                                    self.infoVCs = [vc]
                                }
                                break
                            }
                        }
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
        }
    }
}

#Preview {
    MovietvOSView(item: BaseItem.dummy, appState: AppState(), itemRepository: ItemRepository(authProviding: AppState())) {}
}
