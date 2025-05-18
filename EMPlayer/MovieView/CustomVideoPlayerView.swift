//
//  CustomVideoPlayerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

import AVKit
import os
import SwiftUI

#if os(macOS)
struct MouseMoveTracker: NSViewRepresentable {
    var onMove: () -> Void
    func makeNSView(context _: Context) -> NSView {
        TrackingView(onMove: onMove)
    }

    func updateNSView(_: NSView, context _: Context) {}
    private final class TrackingView: NSView {
        let onMove: () -> Void
        init(onMove: @escaping () -> Void) {
            self.onMove = onMove
            super.init(frame: .zero)
            self.focusRingType = .none
            let opts: NSTrackingArea.Options = [.mouseMoved, .activeAlways, .inVisibleRect]
            addTrackingArea(NSTrackingArea(rect: .zero, options: opts, owner: self, userInfo: nil))
        }

        @available(*, unavailable) required init?(coder _: NSCoder) {
            nil
        }
        override func mouseMoved(with _: NSEvent) {
            onMove()
        }
        override func viewDidMoveToWindow() {
            window?.acceptsMouseMovedEvents = true
        }
    }
}
#endif

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
                    .ignoresSafeArea()
            }
        }
    }
}



#else

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
        ZStack {
            if playerViewModel.isLoading {
                ProgressView("Loading…").tint(.white)
            } else if playerViewModel.hasError {
                Text("Can't load").foregroundColor(.white)
            } else if let player = playerViewModel.player {
                PlatformPlayerView(player: player, viewModel: self.playerViewModel)
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
            #if !os(tvOS)
            if playerViewModel.showControls {
                VStack {
                    Spacer()
                    PlaybackControlsView(playerViewModel: playerViewModel, onClose: onClose)
                        .padding(16)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

#endif
