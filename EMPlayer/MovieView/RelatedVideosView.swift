//
//  RelatedVideosView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/20.
//

import AVKit
import os
import SwiftUI

struct RelatedVideosView: View {
    var appState: AppState
    let items: [BaseItem]
    var onPush: (BaseItem) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 32) {
                ForEach(items, id: \.id) { item in
                    Button(action: {
                        onPush(item)
                    }) {
                        HStack() {
                            AsyncImage(url: item.imageURL(server: appState.server)) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 200, height: 140)
                            .clipped()
                            .cornerRadius(8)
                            .padding(0)
                            
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.footnote)
                                    .lineLimit(2)
                                Text(item.overview ?? "")
                                    .font(.caption2)
                                    .lineLimit(4)
                            }.padding(0)
                        }.padding(0)
                    }
                    .padding(0)
                    .frame(width: 600, height: 160)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 215)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(32)
    }
}

#Preview {
    let appState = AppState()
    RelatedVideosView(appState: appState, items: [BaseItem.generateRandomItem(), BaseItem.generateRandomItem(),BaseItem.generateRandomItem()]) { item in
        print(item)
    }
}
