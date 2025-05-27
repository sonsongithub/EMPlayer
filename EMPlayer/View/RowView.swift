//
//  RowView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/27.
//


import SwiftUI

struct RowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    let items: [ItemNode]
    let width: CGFloat
    let height: CGFloat
    let horizontalSpacing: CGFloat
    var body: some View {
        HStack(spacing: horizontalSpacing) {
            ForEach(items, id: \.id) { item in
                CollectionItemView(node: item)
                    .frame(width: width, height: height)
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
                    .environmentObject(drill)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalSpacing) // ← 左右を均等にする
    }
}
