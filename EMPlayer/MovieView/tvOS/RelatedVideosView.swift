//
//  RelatedVideosView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/20.
//

#if os(tvOS)

import AVKit
import os
import SwiftUI



struct RelatedVideosView: View {
    var appState: AppState
    let items: [ItemNode]
    var target: ItemNode?
    var onPush: (ItemNode) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(items, id: \.id) { item in
                        Button {
                            onPush(item)
                        } label: {
                            CardContentView(appState: appState, node: item)
                                .padding([.leading, .top, .bottom], 16)
                                .padding(.trailing, 20)
                                .frame(height: 230)
                        }
                        .frame(width: 800, height: 230)     // this height is magic number
                    }
                }
            }
            .scrollClipDisabled()
            .buttonStyle(.card)
            .onAppear {
                    if let target = target {
                        withAnimation {
                            proxy.scrollTo(target.id, anchor: .center)
                        }
                    }
            }
        }
    }
}

#Preview {
    let appState = AppState()
    let items = [BaseItem.generateRandomItem(), BaseItem.generateRandomItem(),BaseItem.generateRandomItem()]
    let nodes = items.map { ItemNode(item: $0) }
    RelatedVideosView(appState: appState, items: nodes) { item in
        print(item)
    }
}

#endif
