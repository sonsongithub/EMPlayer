//
//  PlatformPlayerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

#if os(macOS)

import AVKit
import os
import SwiftUI

struct PlatformPlayerView: NSViewRepresentable {
    let player: AVPlayer
    @ObservedObject var viewModel: PlayerViewModel

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = view.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer = playerLayer
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
            if let ctrl = AVPictureInPictureController(playerLayer: playerLayer) {
                ctrl.delegate = viewModel
                viewModel.pipController = ctrl
                DispatchQueue.main.async {
                    viewModel.isPipPossible = ctrl.isPictureInPicturePossible
                }
                _ = ctrl.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { _, change in
                    DispatchQueue.main.async {
                        viewModel.isPipPossible = change.newValue ?? false
                    }
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}

#endif
