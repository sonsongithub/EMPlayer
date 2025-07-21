//
//  MovietvOSView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/18.
//

#if os(tvOS)

import AVKit
import SwiftUI

struct MovieView: View {
    @StateObject private var viewController: MovieViewController
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @State var tabBarVisibility: Visibility = .visible

    @State private var infoVCs: [UIViewController] = []

    var onClose: () -> Void

    init(item: BaseItem, appState: AppState, itemRepository: ItemRepository, onClose: @escaping ()->Void = {}) {
        _viewController = .init(wrappedValue: MovieViewController(currentItem: item, appState: appState, repo: itemRepository))
        self.onClose = onClose
    }

    var body: some View {
        CustomVideoPlayerView(playerViewModel: viewController, onClose: onClose, customInfoControllers: infoVCs)
        .ignoresSafeArea()
        .onDisappear {
            tabBarVisibility = .visible
            viewController.postCurrnetPlayTimeOfUserData()
            viewController.player?.pause()
            viewController.player = nil
            self.onClose()
            NotificationCenter.default.post(name: .collectionViewShouldRefresh, object: nil)
        }
        .toolbar(tabBarVisibility, for: .tabBar)
        .onAppear {
            tabBarVisibility = .hidden
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
                viewController.loadMovieOnSimulator()
                return
            }
            Task {
                do {
                    try await viewController.play()
                    let (_, sameSeasonItems) = await viewController.loadSameSeasonItems()
                    DispatchQueue.main.async {
                        let node_children = sameSeasonItems.map({ ItemNode(item: $0) })
                        guard node_children.count > 0 else { return }
                        let target_node = ItemNode(item: viewController.item)
                        let view = RelatedVideosView(appState: self.appState, items: node_children, target: target_node) { [weak viewController] node in
                            guard let viewController else { return }
                            viewController.avPlayerViewController?.presentedViewController?.dismiss(animated: true)
                            Task {
                                if let item = node.baseItem {
                                    await viewController.playNewVideo(newItem: item)
                                }
                            }
                        }
                        viewController.sameSeasonItems = sameSeasonItems
                        let vc = UIHostingController(rootView: view)
                        vc.title = "Series"
                        self.infoVCs = [vc]
                    }
                } catch {
                    print("Error updating detail: \(error)")
                }
            }
        }
    }
}

#Preview {
    MovieView(item: BaseItem.dummy, appState: AppState(), itemRepository: ItemRepository(authProviding: AppState())) {}
}

#endif
