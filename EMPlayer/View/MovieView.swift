import AVKit
import os
import SwiftUI

// MARK: - PlayerViewModel  (platform-agnostic ------------------------------------------------)

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

#if os(iOS)
    var avPlayerViewController: AVPlayerViewController?
#endif
#if os(macOS)
    var pipController: AVPictureInPictureController?
    @Published var isPipPossible: Bool = false
    @Published var isPipActive:   Bool = false
#endif
    var player: AVPlayer?
    var playerItem: AVPlayerItem? {
        didSet {
            configurePlayer()
        }
    }
    
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

    // ------- private ----------
    private var lastInteraction = Date()
    private func configurePlayer() {
        guard let item = playerItem else {
            hasError = true
            return
        }
        player = AVPlayer(playerItem: item)
        
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
        
        isReady = true
        isLoading = false
        hasError = false
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
}

// MARK: - SeekBar (shared) ---------------------------------------------------------------------

struct CustomSeekBar: View {
    @Binding var value: Double
    let max: Double
    var onFinished: (Double) -> Void = { _ in }
    @Binding var isSeeking: Bool
    let radius: CGFloat = 10

    var body: some View {
        GeometryReader { geometory in
            let width = geometory.size.width
            let percentage = CGFloat(value / max).clamped(to: 0...1)
            let x = radius + (width - 2 * radius) * percentage
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray).frame(height: 4)
                Capsule().fill(Color.white).frame(width: x, height: 4)
                Circle().fill(Color.white).frame(width: radius * 2, height: radius * 2)
                    .position(x: x, y: radius)
            }
            .contentShape(Rectangle().inset(by: -radius))
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { geometory in
                    isSeeking = true
                    value = Double(((geometory.location.x - radius) / (width - 2 * radius)).clamped(to: 0...1)) * max
                }
                .onEnded { _ in isSeeking = false; onFinished(value) })
        }
        .frame(height: radius * 2)
    }
}

// MARK: - Platform-specific AVPlayer container -------------------------------------------------

#if os(macOS)
struct PlatformPlayerView: NSViewRepresentable {
    let player: AVPlayer
    @ObservedObject var viewModel: PlayerViewModel

    func makeNSView(context: Context) -> NSView {
        // 1) Layer-backed NSView を生成
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        
        // 2) AVPlayerLayer を作って NSView.layer にセット
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = view.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer = playerLayer
        
        // 3) PiP コントローラを生成して KVO も登録
        if AVPictureInPictureController.isPictureInPictureSupported() {
            if let ctrl = AVPictureInPictureController(playerLayer: playerLayer) {
                ctrl.delegate = viewModel
                viewModel.pipController = ctrl
                DispatchQueue.main.async {
                    viewModel.isPipPossible = ctrl.isPictureInPicturePossible
                }
                _ = ctrl.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { _, change in
                    DispatchQueue.main.async {
                        viewModel.isPipPossible = change.newValue ?? false
                    }
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}
#else
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
#if os(iOS)
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try? AVAudioSession.sharedInstance().setActive(true)
#endif
        }
        return viewController
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
    }
}
#endif

// MARK: - PlaybackControlsView -----------------------------------------------------------------

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

// MARK: - CustomVideoPlayerView (共通 UI) -------------------------------------------------------

struct CustomVideoPlayerView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    var onClose: () -> Void = {}

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
                }
            }
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

// MARK: - MouseMoveTracker (macOS only) --------------------------------------------------------

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

// MARK: - MovieViewController (API + PlayerVM) -------------------------------------------------

final class MovieViewController: PlayerViewModel {
    let appState: AppState
    let itemRepository: ItemRepository
    let item: BaseItem
    
    init(currentItem: BaseItem, appState: AppState, repo: ItemRepository) {
        item = currentItem
        self.appState = appState
        self.itemRepository = repo
        super.init()
    }

    @MainActor func fetch() async {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            Task {
                let url = Bundle.main.url(forResource: "output01", withExtension: "mp4")!
                let asset = AVURLAsset(url: url)
                DispatchQueue.main.async {
                    self.playerItem = AVPlayerItem(asset: asset)
                    self.player?.play()
                    self.resetInteraction()
                }
            }
        } else {
            do {
                isLoading = true
                let (server, token, _) = try appState.get()
                let detail = try await itemRepository.detail(of: item)
                guard let url = detail.playableVideo(from: server) else {
                    throw APIClientError.invalidURL
                }
                let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["X-Emby-Token": token]])
                DispatchQueue.main.async {
                    self.playerItem = AVPlayerItem(asset: asset)
                    self.player?.play()
                    self.resetInteraction()
                }
            } catch {
                print("Error: \(error)")
                hasError = true
            }
            isLoading = false
        }
    }
}

#if os(macOS)
struct MovieMacView: View {
    @StateObject private var vm: MovieViewController
    var onClose: () -> Void
    // 既存ウィンドウ値保持
    @State private var originalTitleVisibility: NSWindow.TitleVisibility = .visible
    @State private var originalContainsFullSize = false
    @State private var originalToolbarVisibility = false
    @State private var originalTransparent = false
    @State private var originalMovableByBG = false
    @State private var originalSeparatorStyle: NSTitlebarSeparatorStyle = .automatic

    init(item: BaseItem, app: AppState, repo: ItemRepository, onClose: @escaping () -> Void) {
        _vm = .init(wrappedValue: MovieViewController(currentItem: item, appState: app, repo: repo))
        self.onClose = onClose
    }

    var body: some View {
        CustomVideoPlayerView(playerViewModel: vm, onClose: onClose)
            .overlay(
                WindowAccessor { window in
                    if originalTitleVisibility == .visible {
                        originalTitleVisibility = window.titleVisibility
                        originalContainsFullSize = window.styleMask.contains(.fullSizeContentView)
                        originalToolbarVisibility = window.toolbar?.isVisible ?? false
                        originalSeparatorStyle = window.titlebarSeparatorStyle
                        originalTransparent = window.titlebarAppearsTransparent
                        originalMovableByBG = window.isMovableByWindowBackground
                    }
                    applyFullOverlay(to: window)
                }
                .allowsHitTesting(false)
            ).onChange(of: vm.isPipActive) {
                if vm.isPipActive { vm.showControls = false }
            }
            .onDisappear {
                restoreWindow()
            }
            .task {
                await vm.fetch()
            }
    }

    private func applyFullOverlay(to window: NSWindow) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.styleMask.insert(.fullSizeContentView)
        window.toolbar?.isVisible = false
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = false
    }

    private func restoreWindow() {
        guard let window = NSApplication.shared.keyWindow else { return }

        window.titleVisibility            = originalTitleVisibility
        window.titlebarAppearsTransparent = originalTransparent
        window.isMovableByWindowBackground = originalMovableByBG

        if !originalContainsFullSize {
            window.styleMask.remove(.fullSizeContentView)
        }

        // ツールバー可視状態を戻す
        window.toolbar?.isVisible = originalToolbarVisibility

        // セパレータも復帰させる
        window.titlebarSeparatorStyle = originalSeparatorStyle
    }
}
#else
struct MovieiOSView: View {
    @StateObject private var viewController: MovieViewController
    @Environment(\.scenePhase) private var scenePhase
    var onClose: () -> Void

    init(item: BaseItem, appState: AppState, itemRepository: ItemRepository, onClose: @escaping () -> Void = {}) {
        _viewController = .init(wrappedValue: MovieViewController(currentItem: item, appState: appState, repo: itemRepository))
        self.onClose = onClose
    }

    var body: some View {
        CustomVideoPlayerView(playerViewModel: viewController, onClose: onClose)
            .navigationBarHidden(!viewController.showControls)
            .onDisappear {
                viewController.player?.pause()
                viewController.player = nil
            }
            .task {
                print("MovieiOSView task")
                await viewController.fetch()
            }
    }
}
#endif

// MARK: - WindowAccessor ----------------------------------------------------------------------

#if os(macOS)
    struct WindowAccessor: NSViewRepresentable {
        var callback: (NSWindow) -> Void
        func makeNSView(context _: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                if let window = view.window {
                    callback(window)
                }
            }
            return view
        }

        func updateNSView(_: NSView, context _: Context) {}
    }
#endif

// MARK: - Utility -----------------------------------------------------------------------------

private extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
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

extension Notification.Name {
    static let closePlayer = Notification.Name("closePlayer")
}

#if os(macOS)
#Preview {
    MovieMacView(item: BaseItem.dummy, app: AppState(), repo: ItemRepository(authProviding: AppState())) {}
}
#endif

#if os(iOS)
#Preview {
    MovieiOSView(item: BaseItem.dummy, appState: AppState(), itemRepository: ItemRepository(authProviding: AppState())) {}
}
#endif
