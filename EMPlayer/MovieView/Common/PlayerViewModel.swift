//
//  PlayerViewModel.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

import AVKit
import os
import SwiftUI

class PlayerViewModel: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var volume: Float = 0.5 {
        didSet {
            player?.volume = volume
        }
    }
    @Published var showControls = true
    @Published var isSeeking = false
    @Published var isReady = false
    @Published var isLoading = false
    @Published var hasError = false
    
    var doesManageCursor = false
    
    var player: AVPlayer?
    var playerItem: AVPlayerItem? {
        didSet {
            configurePlayer()
        }
    }
#if os(iOS) || os(tvOS)
    var avPlayerViewController: AVPlayerViewController?
#endif
    // ------- private ----------
    private var lastInteraction = Date()
    private func configurePlayer() {
        guard let item = playerItem else {
            hasError = true
            return
        }
        player = AVPlayer(playerItem: item)
        
        isReady = true
        isLoading = false
        hasError = false
#if os(iOS) || os(macOS)
        setupTimerFunc(item: item)
#endif
    }
    
#if os(iOS) || os(macOS)
    
    private func setupTimerFunc(item: AVPlayerItem) {
        
        // duration
        Task { [weak self] in
            guard let self else { return }
            let sec = try? await item.asset.load(.duration).seconds
            await MainActor.run { self.duration = sec?.isFinite ?? false ? sec! : 1 }
        }
        // time observer
        if let t = timeObserved {
            player?.removeTimeObserver(t)
        }
        timeObserved = player?.addPeriodicTimeObserver(forInterval: .init(seconds: 0.2, preferredTimescale: 600), queue: .main) { [weak self] t in
            guard let s = self else { return }
            if !s.isSeeking {
                s.currentTime = t.seconds
            }
            s.isPlaying = (s.player?.rate != 0)
        }
    }

#if os(macOS)
    var pipController: AVPictureInPictureController?
    @Published var isPipPossible: Bool = false
    @Published var isPipActive:   Bool = false
#endif
    
    private var timeObserved: Any?; private var timer: DispatchSourceTimer?
    deinit {
        if let t = timeObserved {
            player?.removeTimeObserver(t)
        }
        timer?.cancel()
#if os(macOS)
        if doesManageCursor {
            NSCursor.unhide()
        }
#endif
    }

    func togglePlay() {
        isPlaying ? player?.pause() : player?.play()
    }
    
    func seek(by s: Double) {
        seek(to: currentTime + s)
    }
    
    func seek(to s: Double) {
        player?.seek(to: .init(seconds: s, preferredTimescale: 600))
    }
    
    func resetInteraction() {
        lastInteraction = Date()
        withAnimation {
            showControls = true
        }
#if os(macOS)
        if doesManageCursor {
            NSCursor.unhide()
        }
#endif
    }

    func startTimer() {
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: .main)
        timer?.schedule(deadline: .now(), repeating: 1)
        timer?.setEventHandler {[weak self] in
            self?.checkTimeout()
        }
        timer?.resume()
    }


    private func checkTimeout() {
        guard isReady, showControls, player?.rate != 0,
              Date().timeIntervalSince(lastInteraction) > 3 else { return }
        withAnimation { showControls = false }
#if os(macOS)
        if doesManageCursor {
            NSCursor.hide()
        }
#endif
    }
    
#if os(macOS)
    func togglePiP() {
        guard let pip = pipController else { return }
        guard pip.isPictureInPicturePossible else { return }
        if pip.isPictureInPictureActive {
            pip.stopPictureInPicture()
        } else {
            pip.startPictureInPicture()
        }
    }
    
    func pictureInPictureControllerWillStartPictureInPicture(_ c: AVPictureInPictureController) {
        print(#function)
        self.isPipActive = true
    }
    func pictureInPictureControllerWillStopPictureInPicture(_ c: AVPictureInPictureController) {
        print(#function)
        self.isPipActive = false
    }
    func pictureInPictureControllerDidStopPictureInPicture(_ c: AVPictureInPictureController) {
        print(#function)
    }
    func pictureInPictureControllerDidStartPictureInPicture(_ c: AVPictureInPictureController) {
        print(#function)
    }
#endif
#endif
}
