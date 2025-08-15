//
//  CustomSeekBar.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/17.
//

#if !os(tvOS)

import AVKit
import os
import SwiftUI

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

private extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
    }
}

#endif
