//  VideoPlayerModule.swift
//  EMPlayer  (macOS + iOS)
//  ------------------------------------------------------------

import SwiftUI
import AVKit
import os

// MARK: - PlayerViewModel  (プラットフォーム非依存)

class PlayerViewModel: ObservableObject {
    @Published var isPlaying  = false
    @Published var currentTime: Double = 0
    @Published var duration   : Double = 1
    @Published var volume     : Float  = 0.5 { didSet { player?.volume = volume } }
    @Published var showControls = true
    @Published var isSeeking   = false
    @Published var isReady     = false
    @Published var isLoading   = false
    @Published var hasError    = false

    var player: AVPlayer?
    var playerItem: AVPlayerItem? {
        didSet { setupPlayerItem() }
    }

    private var lastInteraction = Date()
    private var timeObs: Any?
    private var timer : DispatchSourceTimer?
    deinit { if let t = timeObs { player?.removeTimeObserver(t) }; timer?.cancel() }

    // --------------------------------------------------------

    private func setupPlayerItem() {
        guard let item = playerItem else { resetError(); return }
        player = AVPlayer(playerItem: item)

        // duration
        Task {
            do {
                let sec = try await item.asset.load(.duration).seconds
                await MainActor.run { self.duration = sec.isFinite ? sec : 1 }
            } catch { print(error) }
        }

        // periodic time
        if let t = timeObs { player?.removeTimeObserver(t) }
        timeObs = player?.addPeriodicTimeObserver(forInterval: .init(seconds: 0.2, preferredTimescale: 600),
                                                  queue: .main) { [weak self] t in
            guard let s = self else { return }
            if !s.isSeeking { s.currentTime = t.seconds }
            s.isPlaying = s.player?.rate != 0
        }
        isReady = true
        isLoading = false
    }

    // helpers
    func togglePlay() { isPlaying ? player?.pause() : player?.play() }
    func seek(by sec: Double) { seek(to: currentTime + sec) }
    func seek(to sec: Double) { player?.seek(to: .init(seconds: sec, preferredTimescale: 600)) }
    func resetInteraction() {
        lastInteraction = Date(); withAnimation { showControls = true }
#if os(macOS)
        NSCursor.unhide()
#endif
    }
    func startTimer() {
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: .main)
        timer?.schedule(deadline: .now(), repeating: 1)
        timer?.setEventHandler { [weak self] in self?.checkTimeout() }
        timer?.resume()
    }
    private func checkTimeout() {
        guard isReady, showControls, player?.rate != 0,
              Date().timeIntervalSince(lastInteraction) > 3 else { return }
        withAnimation { showControls = false }
#if os(macOS)
        NSCursor.hide()
#endif
    }
    private func resetError() { isReady=false; isLoading=false; hasError=true }
}

// MARK: - 共通 SeekBar

struct CustomSeekBar: View {
    @Binding var value: Double
    var max: Double
    var onSeekFinished: (Double)->Void = { _ in }
    @Binding var isSeeking: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width; let r: CGFloat = 10
            let pct = CGFloat(value/max).clamped(to: 0...1)
            let x   = r + (w-2*r)*pct
            ZStack(alignment:.leading) {
                Capsule().fill(Color.gray).frame(height:4)
                Capsule().fill(Color.white).frame(width:x, height:4)
                Circle().fill(Color.white).frame(width:20,height:20)
                       .position(x:x,y:10)
            }
            .contentShape(Rectangle().inset(by:-10))
            .gesture(DragGesture(minimumDistance:0)
                .onChanged{ g in isSeeking = true
                    let ratio = ((g.location.x-r)/(w-2*r)).clamped(to:0...1)
                    value = ratio * max
                }
                .onEnded { _ in isSeeking = false; onSeekFinished(value) })
        }.frame(height:20)
    }
}

// MARK: - macOS / iOS ビデオコンテナ

#if os(macOS)
struct PlatformPlayerView: NSViewRepresentable {
    let player: AVPlayer
    func makeNSView(context: Context) -> AVPlayerView {
        let v = AVPlayerView(); v.player = player; v.controlsStyle = .none
        v.videoGravity = .resizeAspect; return v
    }
    func updateNSView(_ v: AVPlayerView, context: Context) { v.player = player }
}
#else
struct PlatformPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController(); c.player = player
        c.showsPlaybackControls=false; c.videoGravity = .resizeAspect; return c
    }
    func updateUIViewController(_ c: AVPlayerViewController, context: Context) { c.player = player }
}
#endif

// MARK: - Playback Controls

struct PlaybackControlsView: View {
    @ObservedObject var vm: PlayerViewModel
    var body: some View {
        VStack(spacing:8) {
            HStack {
                Button { vm.seek(by:-10); vm.resetInteraction() } label:{ Image(systemName:"gobackward.10") }
                Button { vm.togglePlay(); vm.resetInteraction() } label:{
                    Image(systemName: vm.isPlaying ? "pause.circle.fill":"play.circle.fill")
                }
                Button { vm.seek(by: 10); vm.resetInteraction() } label:{ Image(systemName:"goforward.10") }
            }.font(.title).padding()
            CustomSeekBar(value:$vm.currentTime, max:vm.duration,
                          onSeekFinished:{ vm.seek(to:$0);vm.resetInteraction() },
                          isSeeking:$vm.isSeeking)
            .padding(.horizontal)
            HStack {
                Text(vm.currentTime.timeString); Spacer(); Text(vm.duration.timeString)
            }.font(.caption).foregroundColor(.white).padding(.horizontal)
        }.foregroundColor(.white)
    }
}

// MARK: - CustomVideoPlayerView (共通 UI)

struct CustomVideoPlayerView: View {
    @ObservedObject var vm: PlayerViewModel
    var onClose: ()->Void = {}

    var body: some View {
        ZStack {
            if vm.isLoading { ProgressView("Loading…").tint(.white) }
            else if vm.hasError { Text("Can't load").foregroundColor(.white) }
            else if let p = vm.player { PlatformPlayerView(player:p) }

#if os(macOS)
            if !vm.showControls { MouseMoveTracker { vm.resetInteraction() } }
#endif

            if vm.showControls {
                VStack{ Spacer(); PlaybackControlsView(vm:vm) }
            }
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .background(Color.black)
        .onTapGesture { vm.resetInteraction() }
#if os(macOS)
        .onExitCommand(perform:onClose)               // ⎋ で閉じる
#endif
        .onAppear { vm.startTimer() }
        .onDisappear { vm.player?.pause(); vm.player=nil }
    }
}

#if os(macOS)
struct MouseMoveTracker: NSViewRepresentable {
    var onMove:()->Void
    func makeNSView(context:Context)->NSView{
        let v=NSView()
        v.addTrackingArea(NSTrackingArea(rect:.zero, options:[.mouseMoved,.activeAlways,.inVisibleRect], owner:context.coordinator, userInfo:nil))
        return v
    }
    func updateNSView(_ v:NSView,context:Context){}
    func makeCoordinator()->Coordinator{Coordinator(onMove:onMove)}
    class Coordinator:NSObject{
        let onMove:()->Void
        init(onMove:@escaping()->Void){
            self.onMove=onMove
        }
        @objc func mouseMoved(with event: NSEvent){
            onMove()
        }
    }
}
#endif

// MARK: - MovieViewController (API + VM)

final class MovieViewController: PlayerViewModel {
    let appState: AppState
//    private let api = APIClient()
    private let current: BaseItem
    init(currentItem: BaseItem, appState: AppState) {
        self.current = currentItem; self.appState = appState; super.init()
    }
    @MainActor func fetch() async {
        do {
            isLoading = true
            let (server, token, userID) = try appState.get()
            guard let url = current.playableVideo(from: server) else { throw APIClientError.invalidURL }
            let headers = ["X-Emby-Token": token]
            let asset = AVURLAsset(url: url, options:["AVURLAssetHTTPHeaderFieldsKey":headers])
            playerItem = AVPlayerItem(asset: asset)
            player?.play(); resetInteraction()
        } catch { hasError=true } ; isLoading=false
    }
}

// MARK: - iOS 用 MovieView

#if os(iOS)
struct MovieView: View {
    @StateObject private var vm: MovieViewController
    init(item: BaseItem, app: AppState){ _vm = .init(wrappedValue: MovieViewController(currentItem:item, appState:app)) }
    var body: some View {
        CustomVideoPlayerView(vm: vm)
            .onAppear { Task{ await vm.fetch() } }
            .ignoresSafeArea()
    }
}
#endif

// MARK: - macOS 用 MovieMacView (フルウィンドウ用)

#if os(macOS)
struct MovieMacView: View {
    @StateObject private var vm: MovieViewController
    var onClose: ()->Void
    init(item: BaseItem, app: AppState, onClose:@escaping()->Void){
        _vm = .init(wrappedValue: MovieViewController(currentItem:item, appState:app))
        self.onClose=onClose
    }
    var body: some View {
        CustomVideoPlayerView(vm: vm,onClose:onClose)
            .onAppear { Task{ await vm.fetch() } }
    }
}
#endif

fileprivate extension Double {
    var timeString: String {
        guard isFinite else { return "00:00" }
        return String(format:"%02d:%02d", Int(self)/60, Int(self)%60)
    }
}
fileprivate extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self { min(max(self,r.lowerBound), r.upperBound) }
}
