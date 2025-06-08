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
    
    @MainActor
    func detail(of node: BaseItem) async throws -> BaseItem {
        let item = try await api.fetchItemDetail(of: node.id)
        return item
    }
    
    @MainActor
    func detail(of itemID: String) async throws -> BaseItem {
        let item = try await api.fetchItemDetail(of: itemID)
        return item
    }
    
    @MainActor
    func search(query: String) async throws -> [BaseItem] {
        let items = try await api.searchItem(query: query)
        return items
    }
}
