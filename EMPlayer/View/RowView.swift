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
    @State var items: [ItemNode]
    let width: CGFloat
    let height: CGFloat
    let horizontalSpacing: CGFloat
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: horizontalSpacing) {
                ForEach(items, id: \.id) { item in
                    CollectionItemView(node: item, isFocused: focusedID == item.uuid)
                        .frame(width: width, height: height)
                        .environmentObject(appState)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .focused($focusedID, equals: item.uuid)
                        .zIndex(focusedID == item.uuid ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalSpacing)
            .onAppear {
                //            Task {
                //                for i in 0..<items.count {
                //                    if case let .episode(base) = items[i].item {
                //                        let detail = try await itemRepository.detail(of: base)
                //                        self.items[i] = ItemNode(item: detail)
                //                        print(self.items[i])
                //                    }
                //                }
                //                
                //            }
            }
        }
    }
}
