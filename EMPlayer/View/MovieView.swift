//  MovieView.swift
//  EMPlayer

import SwiftUI
import AVKit
import os

#if targetEnvironment(macCatalyst)
import AppKit
#endif

class PlayerViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 1.0
    @Published var volume: Float = 0.5 {
        didSet { player?.volume = volume }
    }
    @Published var showControls: Bool = true

    var player: AVPlayer?
    var playerItem: AVPlayerItem? {
        didSet {
            if let item = playerItem {
                player = AVPlayer(playerItem: item)
                setupPlayer()
            }
        }
    }

    private var lastInteractionTime = Date()
    private var isCursorHidden = false
    private var timeObserverToken: Any?
    private var interactionTimer: DispatchSourceTimer?

    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
        stopTimer()
    }

    private func setupPlayer() {
        guard let player = player, let asset = player.currentItem?.asset else { return }

        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var durationSeconds = CMTimeGetSeconds(asset.duration)
            if durationSeconds.isNaN || durationSeconds.isInfinite {
                durationSeconds = 1.0
            }
            DispatchQueue.main.async {
                self.duration = durationSeconds
            }
        }

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = CMTimeGetSeconds(time)
            self.isPlaying = self.player?.rate != 0
        }
    }

    func togglePlayPause() {
        guard let player = player else { return }
        isPlaying ? player.pause() : player.play()
    }

    func seek(by seconds: Double) {
        guard let player = player else { return }
        let newTime = CMTimeGetSeconds(player.currentTime()) + seconds
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }

    func seek(to seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func resetInteraction() {
        lastInteractionTime = Date()
        showControls = true
#if targetEnvironment(macCatalyst)
        if isCursorHidden {
            isCursorHidden = false
            NSCursor.unhide()
        }
#endif
    }

    func checkInteractionTimeout() {
        print("Checking interaction timeout")
        let elapsed = Date().timeIntervalSince(lastInteractionTime)
        let isCurrentlyPlaying = player?.rate != 0

        if showControls && isCurrentlyPlaying && elapsed > 3.0 {
            showControls = false
#if targetEnvironment(macCatalyst)
            if !isCursorHidden {
                isCursorHidden = true
                NSCursor.hide()
            }
#endif
        }
    }

    func startTimer() {
        stopTimer()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: 1)
        timer.setEventHandler { [weak self] in
            self?.checkInteractionTimeout()
        }
        timer.resume()
        interactionTimer = timer
    }

    func stopTimer() {
        interactionTimer?.cancel()
        interactionTimer = nil
    }
}

// MARK: - CatalystMouseMoveTracker

struct CatalystMouseMoveTracker: UIViewRepresentable {
    var onMove: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let recognizer = UIHoverGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.mouseMoved(_:)))
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onMove: onMove)
    }

    class Coordinator: NSObject {
        let onMove: () -> Void
        init(onMove: @escaping () -> Void) {
            self.onMove = onMove
        }

        @objc func mouseMoved(_ gesture: UIHoverGestureRecognizer) {
            if gesture.state == .changed {
                onMove()
            }
        }
    }
}

// MARK: - AVPlayerView

struct AVPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

// MARK: - CustomSeekBar

struct CustomSeekBar: View {
    @Binding var value: Double
    var max: Double
    var onSeekFinished: ((Double) -> Void)? = nil
    var knobSize: CGSize = CGSize(width: 30, height: 30)

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let knobRadius = knobSize.width / 2
            let safeMinX = knobRadius
            let safeMaxX = width - knobRadius
            let knobX = safeMinX + (safeMaxX - safeMinX) * CGFloat(value / max)

            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray).frame(height: 4)
                Capsule().fill(Color.white).frame(width: knobX, height: 4)
                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize.width, height: knobSize.height)
                    .position(x: knobX, y: knobSize.height / 2)
            }
            .contentShape(Rectangle().inset(by: -knobRadius))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let location = gesture.location.x
                        let ratio = min(Swift.max((location - safeMinX) / (safeMaxX - safeMinX), 0), 1)
                        self.value = ratio * max
                    }
                    .onEnded { gesture in
                        let location = gesture.location.x
                        let ratio = min(Swift.max((location - safeMinX) / (safeMaxX - safeMinX), 0), 1)
                        self.value = ratio * max
                        onSeekFinished?(value)
                    }
            )
        }
        .frame(height: knobSize.height)
    }
}

struct PlaybackControlsView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { viewModel.seek(by: -10); viewModel.resetInteraction() }) {
                    Image(systemName: "gobackward.10").font(.title).padding()
                }
                Button(action: { viewModel.togglePlayPause(); viewModel.resetInteraction() }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.title).padding()
                }
                Button(action: { viewModel.seek(by: 10); viewModel.resetInteraction() }) {
                    Image(systemName: "goforward.10").font(.title).padding()
                }
            }

            HStack {
                CustomSeekBar(value: $viewModel.currentTime, max: viewModel.duration) { newTime in
                    viewModel.seek(to: newTime)
                    viewModel.resetInteraction()
                }
            }.padding(.horizontal)

            HStack {
                Text(timeString(from: viewModel.currentTime))
                Spacer()
                Text(timeString(from: viewModel.duration))
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 10)
        .foregroundColor(.white)
    }

    private func timeString(from seconds: Double) -> String {
        guard !seconds.isNaN else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct CustomVideoPlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let player = viewModel.player {
                AVPlayerView(player: player)
            }

            if !viewModel.showControls {
#if targetEnvironment(macCatalyst)
                CatalystMouseMoveTracker {
                    viewModel.resetInteraction()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
#endif
            }

            if viewModel.showControls {
                VStack {
                    Spacer()
                    PlaybackControlsView(viewModel: viewModel)
                }
            }
        }
        .onTapGesture {
            withAnimation { viewModel.resetInteraction() }
        }
        .navigationBarHidden(!viewModel.showControls)
        .ignoresSafeArea(edges: .vertical)
        .safeAreaInset(edge: .top) {
            if viewModel.showControls {
                HStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "speaker.fill").foregroundColor(.white)
                    CustomSeekBar(
                        value: Binding(get: { Double(viewModel.volume) }, set: { viewModel.volume = Float($0) }),
                        max: 1.0
                    ).frame(width: 120, height: 20)
                    Image(systemName: "speaker.wave.3.fill").foregroundColor(.white)
                }.padding(.top).padding(.trailing, 16)
            }
        }
        .background(Color.black)
        .onDisappear {
            viewModel.stopTimer()
            viewModel.player?.pause()
            viewModel.player?.replaceCurrentItem(with: nil)
        }.onAppear {
            viewModel.startTimer()
        }
    }

    private func timeString(from seconds: Double) -> String {
        guard !seconds.isNaN else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - MovieViewController

class MovieViewController : PlayerViewModel {
    let appState: AppState
    private let apiClient = APIClient()
    @Published var currentItem: BaseItem

    init(currentItem: BaseItem, appState: AppState) {
        self.currentItem = currentItem
        self.appState = appState
        super.init()
    }

    @MainActor
    func fetch() async {
        do {
            let (server, token, userID) = try appState.get()
            let item = try await apiClient.fetchItemDetail(server: server, userID: userID, token: token, of: currentItem)
            DispatchQueue.main.async {
                self.currentItem = item
                if let url = self.currentItem.playableVideo(from: server) {
                    let headers = ["X-Emby-Token": token]
                    let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
                    self.playerItem = AVPlayerItem(asset: asset)
                    self.player?.play()
                    self.resetInteraction()
                }
            }
        } catch {
            print(error)
        }
    }
}

// MARK: - MovieView

struct MovieView: View {
    @StateObject private var controller: MovieViewController

    init(controller: MovieViewController) {
        _controller = StateObject(wrappedValue: controller)
    }

    var body: some View {
        VStack {
            CustomVideoPlayerView(viewModel: controller)
        }
        .onAppear {
            Task {
                await controller.fetch()
            }
        }
        .background(Color.black)
    }
}

#Preview {
    let url = Bundle.main.url(forResource: "output01", withExtension: "mp4")!
    let playerItem = AVPlayerItem(url: url)
    let model = MovieViewController(currentItem: BaseItem.dummy, appState: AppState())
    model.playerItem = playerItem

    return NavigationStack {
        CustomVideoPlayerView(viewModel: model)
            .navigationTitle("プレビュー動画")
            .navigationBarTitleDisplayMode(.inline)
    }
}
