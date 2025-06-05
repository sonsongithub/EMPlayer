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
    @FocusState private var focusedID: UUID?
    let items: [ItemNode]
    let width: CGFloat
    let height: CGFloat
    let horizontalSpacing: CGFloat
    var body: some View {
        HStack(spacing: horizontalSpacing) {
            ForEach(items, id: \.id) { item in
                CollectionItemView(node: item, isFocused: (focusedID == item.uuid))
                    .frame(width: width, height: height)
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
                    .focused($focusedID, equals: item.uuid)
                    .zIndex(focusedID == item.uuid ? 1 : 0)
            }
        }
        .padding()
    }
}
