//
//  SeriesView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/23.
//

import SwiftUI

class EmbySeriesModel : ObservableObject {
    let appState: AppState
    private let apiClient = APIClient()
    var currentItem: BaseItem
    @Published var seasons: [BaseItem] = []
    
    init(currentItem: BaseItem, appState: AppState) {
        self.currentItem = currentItem
        self.appState = appState
    }
    
    @MainActor
    func fetch() async {
        do {
            let (server, token, userID) = try appState.get()
            let items = try await apiClient.fetchItems(server: server, userID: userID, token: token, of: self.currentItem)
            DispatchQueue.main.async {
                self.seasons = items
            }
        } catch {
            print(error)
        }
    }
}

class EmbySeasonModel : ObservableObject {
    let appState: AppState
    private let apiClient = APIClient()
    var currentItem: BaseItem
    
    @Published var episodes: [BaseItem] = []
    
    init(currentItem: BaseItem, appState: AppState) {
        self.currentItem = currentItem
        self.appState = appState
    }
    
    @MainActor
    func fetch() async {
        do {
            let (server, token, userID) = try appState.get()
            let items = try await apiClient.fetchItems(server: server, userID: userID, token: token, of: self.currentItem)
            DispatchQueue.main.async {
                self.episodes = items
                
                Task {
                    
                    for i in (0..<self.episodes.count) {
                        let obj = try await self.apiClient.fetchItemDetail(server: server, userID: userID, token: token, of: self.episodes[i])
                        self.episodes[i] = obj
                    }
                }
                
            }
        } catch {
            print(error)
        }
    }
}

struct HorizontalSeasonEpisodeView: View {
    @EnvironmentObject var appState: AppState
    let item: BaseItem
    
    var body: some View {
        GeometryReader { geometry in
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
                                .frame(width: geometry.size.width, height: geometry.size.height * 3 / 4)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height * 3 / 4)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 3 / 4)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height * 3 / 4)
                        .foregroundColor(.gray)
                }
                Text(item.name)
                    .font(.title2)
                    .dynamicTypeSize(.medium)
                Text(item.overview ?? "?????")
                    .font(.title3)
                    .dynamicTypeSize(.medium)
            }
        }
    }
}

struct HorizontalSeasonView: View {
    @EnvironmentObject var appState: AppState
    
    @StateObject var contentModel: EmbySeasonModel
    
    init(controller: EmbySeasonModel) {
        _contentModel = StateObject(wrappedValue: controller)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer(minLength: 100)
            Text(contentModel.currentItem.name)
                .font(.title)
                .dynamicTypeSize(.xLarge)
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(contentModel.episodes, id: \.id) { item in
                        HorizontalSeasonEpisodeView(item: item).environmentObject(appState)
                            .frame(width: 450, height: 350)
                            .padding(.horizontal)
                    }
                }.frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                contentModel.episodes = Array(repeating: BaseItem.dummy, count: 10)
            } else {
                Task {
                    await contentModel.fetch()
                }
            }
        }
    }
}

struct SeriesView: View {
    @EnvironmentObject var appState: AppState
    
    @StateObject var contentModel: EmbySeriesModel
    
    init(controller: EmbySeriesModel) {
        _contentModel = StateObject(wrappedValue: controller)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                ForEach(contentModel.seasons, id: \.id) { season in
                    let controller = EmbySeasonModel(currentItem: season, appState: appState)
                    HorizontalSeasonView(controller: controller)
                        .environmentObject(appState)
                }
            }
        }
        .onAppear {
            Task {
                await contentModel.fetch()
            }
        }
    }
}

#Preview {
    let appState = AppState(server: "https://example.com", token: "token", userID: "1", isAuthenticated: true)
    let controller = EmbySeriesModel(currentItem: BaseItem.dummy, appState: appState)
    SeriesView(controller: controller).environmentObject(appState)
//    HorizontalSeasonEpisodeView(item: BaseItem.dummy).environmentObject(appState)
//        .border(.red)
//        .frame(width: 400, height: 350)
}
