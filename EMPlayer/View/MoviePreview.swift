//
//  MoviePreview.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/16.
//

import SwiftUI

class MoviePreviewController: ObservableObject {
    @Published var currentItem: BaseItem
    let appState: AppState
    let apiClient = APIClient()
    
    init(currentItem: BaseItem, appState: AppState) {
        self.currentItem = currentItem
        self.appState = appState
    }
    
    @MainActor
    func fetch() async {
        do {
            let (server, token, userID) = try appState.get()
            let object = try await apiClient.fetchItemDetail(server: server, userID: userID, token: token, of: currentItem)
            
            DispatchQueue.main.async {
                self.currentItem = object
            }
        } catch {
            print(error)
        }
    }
}
struct MoviePreview: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var controller: MoviePreviewController

    init(controller: MoviePreviewController) {
        self.controller = controller
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 画像をウィンドウ幅に合わせて表示
                    if let imageURL = controller.currentItem.imageURL(server: appState.server) {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .scaledToFill() // 🔹 隙間なくぴったり表示
                                    .frame(width: proxy.size.width, height: proxy.size.width / 1.5) // 🔹 ウィンドウの幅を基準にする
                                    .clipped() // 🔹 はみ出しを防ぐ
                            default:
                                Color.gray
                                    .frame(width: proxy.size.width, height: proxy.size.width / 1.5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // タイトルと概要テキスト
                    VStack(alignment: .leading, spacing: 10) {
                        Text(controller.currentItem.name)
                            .font(.title)
                            .bold()

                        Text(controller.currentItem.overview ?? "")
                            .font(.body)
                    }
                    .padding(.horizontal)
                }
            }
            //.edgesIgnoringSafeArea(.top) // 🔹 画像をナビゲーションバーの下まで広げる
        }
        .navigationTitle(controller.currentItem.name)
    }
}

#Preview {
    let appState = AppState(server: "https://example.com", token: "token", userID: "1", isAuthenticated: true)
    let con = MoviePreviewController(currentItem: BaseItem.dummy, appState: appState)
    MoviePreview(controller: con).environmentObject(appState)
}
