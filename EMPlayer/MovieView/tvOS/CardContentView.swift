//
//  CardContentView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/29.
//

import AVKit
import os
import SwiftUI

struct CardContentView: View {
    let appState: AppState
    
    @ObservedObject var node: ItemNode
    let id: UUID

    var body: some View {
        GeometryReader { geometry in
            if let item = node.baseItem {
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
                        if let index = item.indexNumber {
                            Text("\(index). \(item.name)")
                                .font(.body)
                                .lineLimit(2)
                        } else {
                            Text(item.name)
                                .font(.body)
                                .lineLimit(2)
                        }
                        Text(item.overview ?? "")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(7)
                        Spacer(minLength: 0)
                    }
                }.preference(key: VisibleItemPreferenceKey.self, value: [id: geometry.frame(in: .global).midX])
                
            } else {
                Text("Error").preference(key: VisibleItemPreferenceKey.self, value: [id: geometry.frame(in: .global).midX])
            }
        }
    }
}
