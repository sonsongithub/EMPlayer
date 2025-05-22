//
//  RelatedVideosView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/20.
//

import AVKit
import os
import SwiftUI

struct CardContentView: View {
    let appState: AppState
    let item: BaseItem

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
                AsyncImage(url: item.imageURL(server: appState.server)) { img in
                    img
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .clipped()
                        .padding(2)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(2)
                Text(item.overview ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(7)
                Spacer(minLength: 0)
            }
        }
    }
}

struct RelatedVideosView: View {
    var appState: AppState
    let items: [BaseItem]
    var onPush: (BaseItem) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 32) {
                ForEach(items, id: \.id) { item in
                    Button {
                        onPush(item)
                    } label: {
                        CardContentView(appState: appState, item: item)
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
    }
}

#Preview {
    let appState = AppState()
    RelatedVideosView(appState: appState, items: [BaseItem.generateRandomItem(), BaseItem.generateRandomItem(),BaseItem.generateRandomItem()]) { item in
        print(item)
    }
}
