//
//  DrillDownStore.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/28.
//

import SwiftUI

final class DrillDownStore: ObservableObject {
    @Published var stack: [ItemNode] = []
    @Published var detail: ItemNode? = nil
    @Published var root: ItemNode? = nil
    @Published var overlay: ItemNode? = nil
    
    var currentNodes: [ItemNode] { stack.last?.children ?? [] }
    
    func reset() {
        detail = nil
        stack = []
        root = nil
    }
    
    func push(_ node: ItemNode) { stack.append(node) }
    func pop()                { _ = stack.popLast() }
}
