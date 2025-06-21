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
        vc.customInfoViewControllers = customInfoControllers
        
        
        if #available(tvOS 16.0, *), let movieVC = viewModel as? MovieViewController, movieVC.hasNextEpisode()
        {
            let nextAction = UIAction(
                title: "Next Episode",
                image: UIImage(systemName: "forward.fill")
            ) { [weak movieVC] _ in
                guard let movieVC else { return }
                movieVC.openNextEpisode()
            }

            let menu = UIMenu(title: "", options: .displayInline, children: [nextAction])
            vc.transportBarCustomMenuItems = [menu]
        } else {
            vc.transportBarCustomMenuItems = []
        }
    }
}

#endif
