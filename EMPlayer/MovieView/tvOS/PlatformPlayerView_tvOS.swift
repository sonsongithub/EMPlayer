//
//  PlatformPlayerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

#if os(tvOS)

import AVKit
import os
import SwiftUI

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
