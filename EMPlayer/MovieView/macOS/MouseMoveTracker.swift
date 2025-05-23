//
//  CustomVideoPlayerView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

#if os(macOS)

import AVKit
import os
import SwiftUI

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
