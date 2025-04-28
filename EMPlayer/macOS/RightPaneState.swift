//
//  RightPaneState.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/27.
//


enum RightPaneState {
    case empty                       // まだ何も選ばれていない
    case detail(BaseItem)            // 左でアイテムを選択
    case searchResults([BaseItem])   // 検索結果を取得済み
}
