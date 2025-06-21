//
//  CustomVideoPlayerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

#if os(macOS) || os(iOS)

import AVKit
import os
import SwiftUI

struct CustomVideoPlayerView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    var onClose: () -> Void = {}

#if os(macOS)
    var macOSButtons: some View {
        HStack(spacing: 20) {
            
            Button(action: { playerViewModel.togglePiP() }) {
                Image(systemName: playerViewModel.isPipActive ? "pip.exit" : "pip")
                    .font(.system(size: 24))
            }
            .foregroundColor(.white)
            .buttonStyle(.borderless)
            .keyboardShortcut("p", modifiers: [.command, .shift])
            
            Button {
                if let window = NSApp.keyWindow {
                    window.toggleFullScreen(nil)
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 24))
            }
            .foregroundColor(.white)
            .buttonStyle(.borderless)
            .keyboardShortcut("f", modifiers: [])
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24)).foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .buttonStyle(.plain)
        .padding([.trailing], 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .keyboardShortcut(.escape, modifiers: [])
        
    }
#endif

    var body: some View {
        GeometryReader { proxy in
            let strategy = MovieViewStrategy(screenSize: proxy.size)
            ZStack {
                if playerViewModel.isLoading {
                    ProgressView("Loading…").tint(.white)
                } else if playerViewModel.hasError {
                    Text("Can't load").foregroundColor(.white)
                } else if let player = playerViewModel.player {
                    PlatformPlayerView(player: player, viewModel: self.playerViewModel)
                        .id(playerViewModel.playerItem?.asset)
                        .ignoresSafeArea()
                }
#if os(macOS)
                if playerViewModel.showControls {
                    macOSButtons
                }
                
                if !playerViewModel.showControls {
                    MouseMoveTracker { playerViewModel.resetInteraction() }
                }
#endif
                if playerViewModel.showControls {
                    VStack {
                        Spacer()
                        PlaybackControlsView(playerViewModel: playerViewModel, onClose: onClose)
                            .padding(16)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .environment(\.movieViewStrategy, strategy)
                    }
                }
            }
            .background(Color.black)
            .contentShape(Rectangle())
            .onTapGesture {
                playerViewModel.resetInteraction()
            }
            .focusable()
#if os(macOS)
#if swift(>=5.7)
            .onExitCommand(perform: onClose)
#else
            .onCancelCommand(perform: onClose)
#endif
#endif
            .onAppear {
                playerViewModel.startTimer()
            }
            .onDisappear {
                playerViewModel.player?.pause()
                playerViewModel.player = nil
            }
            .focusEffectDisabled()
        }
    }
}

#endif
