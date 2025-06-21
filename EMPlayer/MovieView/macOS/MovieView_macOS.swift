//
//  MovieView_macOS.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/18.
//

#if os(macOS)

import AVKit
import os
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow) -> Void
    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}

struct MovieView: View {
    @StateObject private var viewController: MovieViewController
    var onClose: () -> Void
    // 既存ウィンドウ値保持
    @State private var originalTitleVisibility: NSWindow.TitleVisibility = .visible
    @State private var originalContainsFullSize = false
    @State private var originalToolbarVisibility = false
    @State private var originalTransparent = false
    @State private var originalMovableByBG = false
    @State private var originalSeparatorStyle: NSTitlebarSeparatorStyle = .automatic

    init(item: BaseItem, app: AppState, repo: ItemRepository, onClose: @escaping () -> Void) {
        _viewController = .init(wrappedValue: MovieViewController(currentItem: item, appState: app, repo: repo))
        self.onClose = onClose
    }

    var body: some View {
        CustomVideoPlayerView(playerViewModel: viewController, onClose: onClose)
            .overlay(
                WindowAccessor { window in
                    if originalTitleVisibility == .visible {
                        originalTitleVisibility = window.titleVisibility
                        originalContainsFullSize = window.styleMask.contains(.fullSizeContentView)
                        originalToolbarVisibility = window.toolbar?.isVisible ?? false
                        originalSeparatorStyle = window.titlebarSeparatorStyle
                        originalTransparent = window.titlebarAppearsTransparent
                        originalMovableByBG = window.isMovableByWindowBackground
                    }
                    applyFullOverlay(to: window)
                }
                .allowsHitTesting(false)
            ).onChange(of: viewController.isPipActive) {
                if viewController.isPipActive { viewController.showControls = false }
            }
            .onDisappear {
                viewController.postCurrnetPlayTimeOfUserData()
                restoreWindow()
            }
            .task {
                do {
                    try await viewController.play()
                    let sameSeasonItems = try await viewController.loadSameSeasonItems()
                    DispatchQueue.main.async {
                        viewController.sameSeasonItems = sameSeasonItems
                    }
                } catch {
                    print("Error in MovieView: \(error)")
                }
                
            }
    }

    private func applyFullOverlay(to window: NSWindow) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.styleMask.insert(.fullSizeContentView)
        window.toolbar?.isVisible = false
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = false
    }

    private func restoreWindow() {
        guard let window = NSApplication.shared.keyWindow else { return }

        window.titleVisibility            = originalTitleVisibility
        window.titlebarAppearsTransparent = originalTransparent
        window.isMovableByWindowBackground = originalMovableByBG

        if !originalContainsFullSize {
            window.styleMask.remove(.fullSizeContentView)
        }

        // ツールバー可視状態を戻す
        window.toolbar?.isVisible = originalToolbarVisibility

        // セパレータも復帰させる
        window.titlebarSeparatorStyle = originalSeparatorStyle
    }
}

#Preview {
    MovieView(item: BaseItem.dummy, app: AppState(), repo: ItemRepository(authProviding: AppState())) {}
}

#endif
