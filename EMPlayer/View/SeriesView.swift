//
//  SeriesView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/23.
//

import SwiftUI

class SeriesInfo : Identifiable, ObservableObject {
    let id = UUID()
    let season: BaseItem
    @Published var episodes: [BaseItem] = []
    
    init(season: BaseItem) {
        self.season = season
    }
    
    static var dummy: SeriesInfo {
        let obj = SeriesInfo(season: BaseItem.dummy)
        obj.episodes = [BaseItem.dummy, BaseItem.dummy, BaseItem.dummy]
        return obj
    }
}
    
class SeriesViewController: ObservableObject {
    let currentItem: BaseItem
    @Published var seasons: [SeriesInfo] = []
    let appState: AppState
    private let apiClient = APIClient()
    
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
                self.seasons = items.map { SeriesInfo(season: $0) }
                Task {
                    for i in 0..<self.seasons.count {
                        let episodes = try await self.apiClient.fetchItems(server: server, userID: userID, token: token, of: self.seasons[i].season)
                        DispatchQueue.main.async {
                            self.objectWillChange.send()
                            self.seasons[i].episodes = episodes
                            print(episodes)
                            Task {
                                for j in 0..<episodes.count {
                                    let obj = try await self.apiClient.fetchItemDetail(server: server, userID: userID, token: token, of: episodes[j])
                                    DispatchQueue.main.async {
                                        self.seasons[i].episodes[j] = obj
                                        self.objectWillChange.send()
                                        print(obj)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            print(error)
        }
    }
}

struct SeasonView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var season: SeriesInfo
    let width: CGFloat
    let hidesSeasonTitle: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            if !hidesSeasonTitle {
                Text(season.season.name)
                    .font(.largeTitle)
                    .bold()
            }
            ForEach(season.episodes, id: \.id) { episode in
                HStack(spacing: 20) {
                    if let imageURL = episode.imageURL(server: appState.server) {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .scaledToFill()
                                    .cornerRadius(8)
                            default:
                                Color.gray
                            }
                        }
                        .frame(width: width * 0.2, height: width * 0.2 / 16 * 9)                        .cornerRadius(8)
                    }
                    VStack(alignment: .leading) {
                        if let indexNumber = episode.indexNumber {
                            Text("\(indexNumber). \(episode.name)")
                                .font(.title)
                        } else {
                            Text(episode.name)
                                .font(.title)
                        }
                        Text(episode.overview ?? "")
                        Spacer()
                    }.frame(height: width * 0.2 / 16 * 9)
                }
                .padding(.horizontal, 10)
            }
        }.padding(.bottom, 40)
    }
}

struct SeriesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var contentModel: SeriesViewController

    init(controller: SeriesViewController) {
        _contentModel = StateObject(wrappedValue: controller)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(contentModel.seasons) { season in
                        SeasonView(season: season, width: proxy.size.width, hidesSeasonTitle: (contentModel.seasons.count <= 1)).environmentObject(appState)
                    }
                }
                .padding(.top)
                .padding(.horizontal)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            Task {
                await contentModel.fetch()
            }
        }
        .navigationTitle(Text(contentModel.currentItem.name))
    }
}

#Preview {
    let appState = AppState(server: "https://example.com", token: "token", userID: "1", isAuthenticated: true)
    SeasonView(season: SeriesInfo.dummy, width: 400, hidesSeasonTitle: false).environmentObject(appState)
}
