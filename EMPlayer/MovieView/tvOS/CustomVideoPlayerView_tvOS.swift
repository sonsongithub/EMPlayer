//
//  CustomVideoPlayerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

import AVKit
import os
import SwiftUI

#if os(tvOS)

struct CustomVideoPlayerView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    var onClose: () -> Void = {}
    let customInfoControllers: [UIViewController]
    
    var body: some View {
        ZStack {
            if playerViewModel.isLoading {
                ProgressView("Loading…").tint(.white)
            } else if playerViewModel.hasError {
                Text("Can't load").foregroundColor(.white)
            } else if let player = playerViewModel.player {
                PlatformPlayerView(player: player, viewModel: self.playerViewModel, customInfoControllers: customInfoControllers)
                    .id(playerViewModel.playerItem?.asset)
                    .ignoresSafeArea()
            }
        }
    }
}

#endif
