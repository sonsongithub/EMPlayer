//
//  PlaybackControlsView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

#if !os(tvOS)

import AVKit
import os
import SwiftUI

struct PlaybackControlsView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @State private var isSeekingVolume = false
    var onClose: () -> Void = {}
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    private var soubdVolume: some View {
        HStack(spacing: 4) {
            Image(systemName: "speaker.fill")
            CustomSeekBar(
                value: Binding(
                    get: { Double(playerViewModel.volume) },
                    set: { playerViewModel.volume = Float($0) }
                ),
                max: 1.0,
                onFinished: { _ in playerViewModel.resetInteraction() },
                isSeeking: $isSeekingVolume
            )
            .frame(width: 120, height: 20)
            Image(systemName: "speaker.wave.3.fill")
        }
        .padding(.leading, 12)
    }

    private var transportButtons: some View {
        
        HStack(spacing: 24) {
            Button { playerViewModel.seek(by: -10); playerViewModel.resetInteraction() } label: {
                Image(systemName: "gobackward.10")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.leftArrow, modifiers: [])
            
            Button { playerViewModel.togglePlay(); playerViewModel.resetInteraction() } label: {
                Image(systemName: playerViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.space, modifiers: [])
            
            Button {
                playerViewModel.seek(by: 10); playerViewModel.resetInteraction()
            } label: {
                Image(systemName: "goforward.10")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.rightArrow, modifiers: [])
        }
        .font(.title)
    }

    var body: some View {
        VStack(spacing: 20) {
             
            if hSizeClass == .compact {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    transportButtons
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                soubdVolume
            } else {
                HStack(spacing: 0) {
                    soubdVolume.hidden()
                    Spacer(minLength: 0)
                    transportButtons
                    Spacer(minLength: 0)
                    soubdVolume
                }
                .padding(.horizontal)
            }
            VStack(spacing: 0) {
                CustomSeekBar(value: $playerViewModel.currentTime,
                              max: playerViewModel.duration,
                              onFinished: { playerViewModel.seek(to: $0); playerViewModel.resetInteraction() },
                              isSeeking: $playerViewModel.isSeeking)
                .padding(.horizontal)
                
                HStack {
                    Text(playerViewModel.currentTime.timeString)
                    Spacer()
                    Text(playerViewModel.duration.timeString)
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal)
            }
        }
        .foregroundColor(.white)
    }
}

private extension Double {
    var timeString: String {
        guard isFinite else {
            return "00:00"
        }
        return String(format: "%02d:%02d", Int(self) / 60, Int(self) % 60)
    }
}

#endif
