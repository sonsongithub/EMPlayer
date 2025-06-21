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
    var toNext: () -> Void = {}
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.movieViewStrategy) var strategy
    
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
            Spacer()
            if let viewController = playerViewModel as? MovieViewController {
                HStack {
                    Text(viewController.item.name)
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)
            }
            if !strategy.isPad && strategy.isPortrait {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    transportButtons
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                soubdVolume
            } else {
                Group {
                    ZStack {
                        if playerViewModel.hasNextEpisode() {
                            VStack(alignment: .leading) {
                                HStack(spacing: 0) {
                                    Button {
                                        if let viewController = playerViewModel as? MovieViewController {
                                            viewController.openNextEpisode()
                                        }
                                    } label: {
                                        Image(systemName: "forward.fill")
                                        Text("Next episode")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .bold()
                                    }
                                    .buttonStyle(.bordered)
                                    .background(.white.opacity(0.2))
                                    .cornerRadius(6)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        VStack(alignment: .center) {
                            HStack(spacing: 0) {
                                transportButtons
                            }
                        }
                        VStack(alignment: .trailing) {
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                soubdVolume
                            }
                        }
                    }
                }
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

#if os(iOS)

#Preview {
    MovieView(item: BaseItem.dummy, appState: AppState(), itemRepository: ItemRepository(authProviding: AppState())) {}
}

#endif

#endif
