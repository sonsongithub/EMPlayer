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
            LazyHStack(spacing: 16) {
                ForEach(items, id: \.id) { item in
                          Button(action: {
                              onPush(item)
                          }) {
                            VStack(alignment: .leading, spacing: 8) {
                              AsyncImage(url: item.imageURL(server: appState.server)) { img in
                                img.resizable().scaledToFill()
                              } placeholder: {
                                Color.gray.opacity(0.3)
                              }
                              .frame(width: 200, height: 112)
                              .clipped()
                              .cornerRadius(8)
                              .padding(.horizontal, 4)
                              .padding(.vertical, 4)

                              Text(item.name)
                                .font(.footnote)
                                .lineLimit(2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                            .frame(width: 200)
                            .padding(4)
                          }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
}

#Preview {
    let appState = AppState()
    RelatedVideosView(appState: appState, items: [BaseItem.generateRandomItem(), BaseItem.generateRandomItem(),BaseItem.generateRandomItem()]) { item in
        print(item)
    }
}
