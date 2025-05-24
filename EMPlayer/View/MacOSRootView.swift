//
//  MacOSRootView.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/19.
//

import SwiftUI

#if os(macOS)

struct SeasonView: View {
    @EnvironmentObject var drill: DrillDownStore
    @EnvironmentObject var itemRepository: ItemRepository
    
    var body: some View {
        if let detail = drill.detail, case .season(_) = detail.item, detail.children.count > 0 {
            List(detail.children) { child in
                Text(child.display())
                    .onTapGesture {
                        Task {
                            do {
                                if case let .episode(base) = child.item {
                                    let a = try await itemRepository.detail(of: base)
                                    DispatchQueue.main.async {
                                        drill.overlay = ItemNode(item: a)
                                    }
                                }
                            } catch {
                                print("Error: \(error)")
                            }
                        }
                    }
            }
        } else {
            Text("None")
                .onAppear {
                    if let detail = drill.detail, case let .season(base) = detail.item {
                        Task {
                            let items = try await itemRepository.children(of: base)
                            print("items: \(items.count)")
                            let children = items.map({ ItemNode(item: $0)})
                            DispatchQueue.main.async {
                                drill.detail = ItemNode(item: base, children: children)
                            }
                        }
                    }
                }
        }
    }
}

struct DetailView: View {
    @EnvironmentObject var drill: DrillDownStore
    @EnvironmentObject var itemRepository: ItemRepository
    
    var body: some View {
        switch drill.detail?.item {
        case .some(.movie(let base)):
            Text(base.name)
                .onTapGesture {
                    drill.overlay = drill.detail
                }
        case .some(.season(_)):
            SeasonView()
                .environmentObject(drill)
                .environmentObject(itemRepository)
        case .some(.episode(let base)):
            Text(base.name)
        default:
            Text("None")
        }
    }
}
    
struct ColumnDrillView: View {
    @EnvironmentObject var drill: DrillDownStore
    @EnvironmentObject var repo : ItemRepository
    
    var body: some View {
        VSplitView {
            HSplitView {
                ForEach(Array(drill.stack.enumerated()), id: \.element.id) { index, node in
                    if index ==  drill.stack.count - 1 {
                        ListColumn(index: index, node: node)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ListColumn(index: index, node: node)
                            .frame(minWidth: 200, maxWidth: 300, maxHeight: .infinity)
                    }
                }
            }.frame(minWidth: 800)
            DetailView()
                .environmentObject(drill)
                .environmentObject(repo)
                .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        }
    }
}

private struct ListColumn: View {
    @EnvironmentObject var drill: DrillDownStore
    @EnvironmentObject var repo : ItemRepository
    
    let index: Int         // 自分が何階層めか
    @ObservedObject var node: ItemNode
    
    var body: some View {
        List(node.children) { child in
            if child.selected {
                Text(child.display())
                    .bold()
                    .listRowBackground(Color.gray.opacity(0.2))
                    .onTapGesture {
                        child.selected = true
                        Task { await open(child, from: index) }
                    }
            } else {
                Text(child.display())
                    .onTapGesture {
                        node.children.forEach { $0.selected = false }
                        child.selected = true
                        Task { await open(child, from: index) }
                    }
            }
        }
        .overlay {
            if node.isLoading { ProgressView() }
        }
    }
    
    // タップ時
    @MainActor
    private func open(_ child: ItemNode, from level: Int) async {
        // ① deeper or play
        switch child.item {
        case .series(let base), .collection(let base), .boxSet(let base):
            Task {
                let items = try await repo.children(of: base)
                print("items: \(items.count)")
                let children = items.map({ ItemNode(item: $0)})
                DispatchQueue.main.async {
                    drill.stack = Array(drill.stack.prefix(level + 1))
                    drill.push(ItemNode(item: nil, children: children))
                }
            }
        case .season(let base):
            drill.stack = Array(drill.stack.prefix(level + 1))
            drill.detail = ItemNode(item: base)
        case .movie(let base):
            drill.stack = Array(drill.stack.prefix(level + 1))
            drill.detail = ItemNode(item: base)
        case .episode(let base):
            drill.stack = Array(drill.stack.prefix(level + 1))
            drill.detail = ItemNode(item: base)
        default:
            drill.stack = Array(drill.stack.prefix(level + 1))
            drill.detail = child
        }
    }
}
    
#endif

