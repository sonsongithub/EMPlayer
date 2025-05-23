//
//  PlatformPlayerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

#if os(iOS)

import AVKit
import os
import SwiftUI

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

#endif
