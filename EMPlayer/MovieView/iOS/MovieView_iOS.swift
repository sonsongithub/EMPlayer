//
//  MovieView_iOS.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/18.
//

#if os(iOS)

import AVKit
import SwiftUI

import SwiftUI

extension View {
    func prefersHomeIndicatorAutoHidden() -> some View {
        background(HiddenHomeIndicatorHostingController())
    }
}

struct HiddenHomeIndicatorHostingController: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        HiddenHomeIndicatorViewController(rootView: AnyView(EmptyView()))
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

final class HiddenHomeIndicatorViewController: UIHostingController<AnyView> {
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

struct MovieView: View {
    @EnvironmentObject var itemRepository: ItemRepository
    @StateObject private var viewController: MovieViewController
    @Environment(\.scenePhase) private var scenePhase
    var onClose: () -> Void

    init(item: BaseItem, appState: AppState, itemRepository: ItemRepository, onClose: @escaping () -> Void = {}) {
        _viewController = .init(wrappedValue: MovieViewController(currentItem: item, appState: appState, repo: itemRepository))
        self.onClose = onClose
    }

    var body: some View {
        GeometryReader { geometry in
            CustomVideoPlayerView(playerViewModel: viewController, onClose: onClose)
                .navigationBarHidden(!viewController.showControls)
                .onDisappear {
                    viewController.postCurrnetPlayTimeOfUserData()
                    viewController.player?.pause()
                    viewController.player = nil
                }
                .task {
                    do {
                        try await viewController.play()
                        let (_, sameSeasonItems) = try await viewController.loadSameSeasonItems()
                        DispatchQueue.main.async {
                            viewController.sameSeasonItems = sameSeasonItems
                        }
                    } catch {
                        print("Error in MovieView: \(error)")
                    }
                }.prefersHomeIndicatorAutoHidden()
        }
    }
}

#Preview {
    MovieView(item: BaseItem.dummy, appState: AppState(), itemRepository: ItemRepository(authProviding: AppState())) {}
        
}

#endif
