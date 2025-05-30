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
        .onDisappear {
            viewController.player?.pause()
            viewController.player = nil
        }.toolbar(tabBarVisibility, for: .tabBar)
        .onDisappear() {
            tabBarVisibility = .visible
        }
        .onAppear {
            tabBarVisibility = .hidden
            Task {
                await viewController.fetch()
                
                var children: [BaseItem] = []
                
                do {
                    children.append(contentsOf: try await viewController.getSeason(of: viewController.item))
                } catch {
                    print("Error: \(error)")
                }
                
                for i in 0..<children.count {
                    do {
                        let detail = try await itemRepository.detail(of: children[i])
                        children[i] = detail
                    } catch {
                        print("Error: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    let node_children = children.map({ ItemNode(item: $0) })
                    let target_node = ItemNode(item: viewController.item)
                    let view = RelatedVideosView(appState: self.appState, items: node_children, target: target_node) { node in
                        viewController.avPlayerViewController?.presentedViewController?.dismiss(animated: true)
                        Task {
                            if let item = node.baseItem {
                                await viewController.playNewVideo(newItem: item)
                            }
                        }
                    }
                    let vc = UIHostingController(rootView: view)
                    vc.title = "Series"
                    self.infoVCs = [vc]
                }
            }
        }
    }
}

#Preview {
    MovieView(item: BaseItem.dummy, appState: AppState(), itemRepository: ItemRepository(authProviding: AppState())) {}
}

#endif
