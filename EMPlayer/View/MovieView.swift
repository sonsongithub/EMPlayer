//
//  MovieView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

import SwiftUI
import AVKit

class MovieViewController : ObservableObject {
    let appState: AppState
    private let apiClient = APIClient()
    @Published var currentItem: BaseItem
    
    @Published var asset: AVURLAsset?
    
    @Published var currentTitle: String?
    
    init(currentItem: BaseItem, appState: AppState) {
        self.currentItem = currentItem
        self.appState = appState
    }
    
    @MainActor
    func fetch() async {
        do {
            let (server, token, userID) = try appState.get()
            let item = try await apiClient.fetchItemDetail(server: server, userID: userID, token: token, of: self.currentItem)
            DispatchQueue.main.async {
                self.currentItem = item
                if let url = self.currentItem.playableVideo(from: server) {
                    let headers = ["X-Emby-Token": token]
                    self.asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey" : headers])
                    self.currentTitle = self.currentItem.name
                }
            }
        } catch {
            print(error)
        }
    }
}

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

struct CustomSeekBar: View {
    @Binding var value: Double
    var max: Double
    var onSeekFinished: ((Double) -> Void)? = nil
    var knobSize: CGSize = CGSize(width: 30
                                  , height: 30)
    var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let knobRadius = knobSize.width / 2
                let safeMinX = knobRadius
                let safeMaxX = width - knobRadius
                let knobX = safeMinX + (safeMaxX - safeMinX) * CGFloat(value / max)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray)
                        .frame(height: 4)

                    Capsule()
                        .fill(Color.white)
                        .frame(width: knobX, height: 4)

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

class PlayerViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 1.0
    @Published var volume: Float = 0.5 {
        didSet {
            player.volume = volume
        }
    }

    let player: AVPlayer
    private var timeObserverToken: Any?

    init(playerItem: AVPlayerItem) {
        self.player = AVPlayer(playerItem: playerItem)
        self.player.volume = volume

        let asset = playerItem.asset
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var durationSeconds = CMTimeGetSeconds(asset.duration)
            if durationSeconds.isNaN || durationSeconds.isInfinite {
                durationSeconds = 1.0
            }
            DispatchQueue.main.async {
                self.duration = durationSeconds
            }
        }

        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.2, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = CMTimeGetSeconds(time)
            self.isPlaying = self.player.rate != 0
        }
    }

    deinit {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }

    func seek(by seconds: Double) {
        let current = CMTimeGetSeconds(player.currentTime())
        let newTime = current + seconds
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }

    func seek(to seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }
}

struct CustomVideoPlayerView: View {
    @StateObject private var viewModel: PlayerViewModel

    @State private var showControls = true
    @State private var title: String = "unknown"
    @State private var onNext: (() -> Void)? = nil
    @State private var onPrevious: (() -> Void)? = nil

    init(playerItem: AVPlayerItem) {
        _viewModel = StateObject(wrappedValue: PlayerViewModel(playerItem: playerItem))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            AVPlayerView(player: viewModel.player)

            if showControls {
                VStack {
                    Spacer()

                    VStack(spacing: 8) {
                        HStack {
                            Button(action: { viewModel.seek(by: -10) }) {
                                Image(systemName: "gobackward.10")
                                    .font(.title)
                                    .padding()
                            }

                            Button(action: {
                                viewModel.togglePlayPause()
                            }) {
                                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title)
                                    .padding()
                            }

                            Button(action: { viewModel.seek(by: 10) }) {
                                Image(systemName: "goforward.10")
                                    .font(.title)
                                    .padding()
                            }
                        }

                        HStack {
                            Text(title)
                            Spacer()
                        }.padding(.leading, 40)

                        HStack(spacing: 20) {
                            if let onPrevious = onPrevious {
                                Button(action: { onPrevious() }) {
                                    Text("Previous")
                                        .font(.subheadline)
                                        .padding()
                                }
                            }
                            if let onNext = onNext {
                                Button(action: { onNext() }) {
                                    Text("Next")
                                        .font(.subheadline)
                                        .padding()
                                }
                            }
                            Spacer()
                        }

                        HStack {
                            Spacer(minLength: 20)
                            CustomSeekBar(value: $viewModel.currentTime, max: viewModel.duration) { newTime in
                                viewModel.seek(to: newTime)
                            }
                            .padding(.horizontal)
                            Spacer(minLength: 20)
                        }

                        HStack {
                            Text(timeString(from: viewModel.currentTime))
                            Spacer()
                            Text(timeString(from: viewModel.duration))
                        }
                        .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                }
                .foregroundColor(.white)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
        .navigationBarHidden(!showControls)
        .ignoresSafeArea(edges: .vertical)
        .safeAreaInset(edge: .top) {
            if showControls {
                HStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.white)
                    CustomSeekBar(
                        value: Binding(
                            get: { Double(viewModel.volume) },
                            set: {
                                viewModel.volume = Float($0)
                            }
                        ),
                        max: 1.0
                    )
                    .frame(width: 120, height: 20)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.white)
                }
                .padding(.top)
                .padding(.trailing, 16)
            }
        }
        .background(Color.black)
        .onDisappear {
            viewModel.player.pause()
            viewModel.player.replaceCurrentItem(with: nil)
        }
        .onAppear {
            viewModel.player.play()
        }
    }

    private func timeString(from seconds: Double) -> String {
        guard !seconds.isNaN else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct MovieView: View {
    @StateObject private var appState = AppState()
    @StateObject private var controller: MovieViewController
    
    @State var url: URL?
    @State var asset: AVURLAsset?
    
    init(controller: MovieViewController) {
        _controller = StateObject(wrappedValue: controller)
    }
    
    var body: some View {
        VStack {
            if let asset = controller.asset {
                CustomVideoPlayerView(playerItem: AVPlayerItem(asset: asset))
            }
        }
        .onAppear() {
            Task {
                await controller.fetch()
            }
        }
        .background(Color.black)
    }
}
