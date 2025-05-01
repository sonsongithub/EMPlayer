//
//  ItemRepository.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/27.
//

import SwiftUI

final class ItemRepository : ObservableObject {
    private let api: APIClient
    
    /// キャッシュ: item.id → ItemNode
    private var cache: [String: ItemNode] = [:]
    
    init(authProviding: AuthProviding) {
        self.api = APIClient(authProviding: authProviding)
    }
    
    func node(for base: BaseItem) -> ItemNode {
        if let cached = cache[base.id] { return cached }
        let node = ItemNode(item: base)
        cache[base.id] = node
        return node
    }
    
    @MainActor
    func userInfo() async throws -> User {
        let user = try await api.userInfo()
        return user
    }
    
    @MainActor
    func root() async throws -> [BaseItem] {
        let items = try await api.fetchUserView()
        return items
    }
    
    @MainActor
    func children(of node: BaseItem) async throws -> [BaseItem] {
        let items = try await api.fetchItems(parent: node)
        return items
    }

    /// 子要素を読み込んで node.children にセット
    @MainActor
    func loadChildren(of node: ItemNode) async {
        guard node.children == nil, node.isLoading == false else { return }
        node.isLoading = true
        do {
//            // API 実装は type で分岐
//            let bases = try await api.fetchItems(server: <#T##String#>, userID: <#T##String#>, token: <#T##String#>, of: <#T##BaseItem#>)
//            node.children = bases.map { self.node(for: $0) }
//            node.loadError = nil
        } catch {
            node.loadError = error
        }
        node.isLoading = false
    }
}
