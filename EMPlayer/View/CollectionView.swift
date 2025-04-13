//
//  CollectionView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

class CollectionViewController: ObservableObject {
    
    let currentItem: BaseItem
    
    static func forPreivew(appState: AppState) -> CollectionViewController {
        let con = CollectionViewController(currentItem: BaseItem.dummy, appState: appState)
        for _ in (0..<20) {
            con.items.append(BaseItem.dummy)
        }
        return con
    }
    
    let appState: AppState
    private let apiClient = APIClient()
    
    @Published var items: [BaseItem] = []
    
    init(currentItem: BaseItem, appState: AppState) {
        self.currentItem = currentItem
        self.appState = appState
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.items = [BaseItem.dummy, BaseItem.dummy, BaseItem.dummy, BaseItem.dummy, BaseItem.dummy, BaseItem.dummy]
        }
    }
    
    @MainActor
    func fetch() async {
        do {
            let (server, token, userID) = try appState.get()
            let items = try await apiClient.fetchItems(server: server, userID: userID, token: token, of: self.currentItem)
            DispatchQueue.main.async {
                self.items = items
            }
        } catch {
            print(error)
        }
    }
}

struct CollectionItemView: View {
    let item: BaseItem
    let appState: AppState
    let width = CGFloat(100)
    let height = CGFloat(300)
    var body: some View {
        GeometryReader { geometry in
            NavigationLink(destination: item.nextView(appState: appState)) {
                VStack {
                    if let url = item.imageURL(server: appState.server) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .foregroundColor(.gray)
                    }
                    Text(item.name)
                        .font(.headline)
                        .dynamicTypeSize(.xSmall)
                }
            }
        }
    }
}

struct RowView: View {
    let appState: AppState
    let items: [BaseItem]
    let width: CGFloat
    let height: CGFloat
    let horizontalSpacing: CGFloat
    var body: some View {
        HStack(spacing: horizontalSpacing) {
            ForEach(items, id: \.id) { item in
                CollectionItemView(item: item, appState: appState)
                    .frame(width: width, height: height)
            }
        }
        .padding()
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

struct CollectionView: View {
    
    #if os(tvOS)
    let minWidth: CGFloat = 60  // カラムの最小幅
    let maxWidth: CGFloat = 200  // カラムの最大幅
    let horizontalSpacing: CGFloat = 40
    let itemPerRow: CGFloat = 8
    let space: CGFloat = 70
    #else
    let minWidth: CGFloat = 60  // カラムの最小幅
    let maxWidth: CGFloat = 150  // カラムの最大幅
    let horizontalSpacing: CGFloat = 16
    let itemPerRow: CGFloat = 8
    let space: CGFloat = 8
    #endif
    @EnvironmentObject var appState: AppState
    
    @StateObject private var controller: CollectionViewController
    
    init(controller: CollectionViewController) {
        _controller = StateObject(wrappedValue: controller)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let itemPerRow = max(1, Int(availableWidth / maxWidth))
                let columnWidth = max(minWidth, (availableWidth - (horizontalSpacing * CGFloat(itemPerRow + 1))) / CGFloat(itemPerRow))
                let height = floor(columnWidth * 10.0 / 7.0 + 10)
                ScrollView {
                    VStack(alignment: .leading, spacing: space) {
                        let rows = self.controller.items.chunked(into: itemPerRow)
                        ForEach(rows.indices, id: \.self) { rowIndex in
                            RowView(appState: appState, items: rows[rowIndex], width: columnWidth, height: height, horizontalSpacing: horizontalSpacing)
                        }
                        Spacer()
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            Task {
                await controller.fetch()
            }
        }
        .navigationTitle(controller.currentItem.name)
    }
}

#Preview {
    let appState = AppState(server: "https://example.com", token: "token", userID: "1", isAuthenticated: true)
    let controller = CollectionViewController.forPreivew(appState: appState)
    CollectionView(controller: controller).environmentObject(appState)
}

#Preview {
    CollectionItemView(item: BaseItem.dummy, appState: AppState())
        .frame(width: 200, height: 320)
}
