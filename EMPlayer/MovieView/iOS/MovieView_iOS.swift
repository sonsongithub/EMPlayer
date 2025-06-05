//
//  MovieView_iOS.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/18.
//

#if os(iOS)

import AVKit
import SwiftUI

struct MovieView: View {
    @StateObject private var viewController: MovieViewController
    @Environment(\.scenePhase) private var scenePhase
    var onClose: () -> Void

    init(item: BaseItem, appState: AppState, itemRepository: ItemRepository, onClose: @escaping () -> Void = {}) {
        _viewController = .init(wrappedValue: MovieViewController(currentItem: item, appState: appState, repo: itemRepository))
        self.onClose = onClose
    }

    var body: some View {
        CustomVideoPlayerView(playerViewModel: viewController, onClose: onClose)
            .navigationBarHidden(!viewController.showControls)
            .onDisappear {
                viewController.player?.pause()
                viewController.player = nil
            }
            .task {
                await viewController.fetch()
            }
    }
}

#Preview {
    MovieView(item: BaseItem.dummy, appState: AppState(), itemRepository: ItemRepository(authProviding: AppState())) {}
}

#endif
