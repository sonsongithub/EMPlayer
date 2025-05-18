//
//  PlatformPlayerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//


import AVKit
import os
import SwiftUI

#if os(macOS)

struct PlatformPlayerView: NSViewRepresentable {
    let player: AVPlayer
    @ObservedObject var viewModel: PlayerViewModel

    func makeNSView(context: Context) -> NSView {
        // 1) Layer-backed NSView を生成
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        
        // 2) AVPlayerLayer を作って NSView.layer にセット
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = view.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer = playerLayer
        
        // 3) PiP コントローラを生成して KVO も登録
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

#elseif os(iOS)
struct PlatformPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    @ObservedObject var viewModel: PlayerViewModel

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let viewController = AVPlayerViewController()
        viewController.player = player
        viewController.showsPlaybackControls = false
        viewController.allowsPictureInPicturePlayback = true
        viewModel.avPlayerViewController = viewController
        DispatchQueue.main.async {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        return viewController
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
    }
}
#elseif os(tvOS)
struct PlatformPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    @ObservedObject var viewModel: PlayerViewModel

    /// ここを追加：SwiftUI 側から渡すカスタム Info VC
    let customInfoControllers: [UIViewController]

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls               = true
        vc.allowsPictureInPicturePlayback      = true
        vc.isSkipBackwardEnabled               = true
        vc.isSkipForwardEnabled                = true
        vc.playbackControlsIncludeTransportBar = true
        vc.playbackControlsIncludeInfoViews    = true

        viewModel.avPlayerViewController = vc
        vc.player?.play()
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        // SwiftUI 側で渡された最新の customInfoControllers を反映
        vc.customInfoViewControllers = customInfoControllers
    }
}
#endif
