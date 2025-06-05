//
//  ItemNodeView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/24.
//


import SwiftUI

struct ItemNodeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore

    @ObservedObject var node: ItemNode

    var body: some View {
        List {
            ForEach(node.children, id: \.id) { child in
                Button {
                    drill.stack.append(child)
                } label: {
                    Text(child.display())
                }
            }
        }
        .onAppear {
            Task {
                switch node.item {
                case let .collection(base), let .series(base), let .boxSet(base), let .season(base):
                    Task {
                        let items = try await self.itemRepository.children(of: base)
                        print("items: \(items.count)")
                        let children = items.map({ ItemNode(item: $0)})
                        DispatchQueue.main.async {
                            node.children = children
                        }
                    }
                default:
                    do {}
                }
            }
        }
    }
}
