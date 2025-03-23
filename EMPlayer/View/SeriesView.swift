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
    
    init(season: BaseItem, episodes: [BaseItem]) {
        self.season = season
        self.episodes = episodes
    }
    
    static var dummy: SeriesInfo {
        let obj = SeriesInfo(season: BaseItem.dummy)
        obj.episodes = [BaseItem.dummy, BaseItem.dummy, BaseItem.dummy]
        return obj
    }
    
    func sortEpisodes() {
        episodes.sort { $0.indexNumber ?? 0 < $1.indexNumber ?? 0 }
    }
}
    
class SeriesViewController: ObservableObject {
    @Published var currentItem: BaseItem
    @Published var seasons: [SeriesInfo] = []
    let appState: AppState
    private let apiClient = APIClient()
    var isLoaded = false
    
    init(currentItem: BaseItem, appState: AppState) {
        self.currentItem = currentItem
        self.appState = appState
    }
    
    init(currentItem: BaseItem, appState: AppState, seasons: [SeriesInfo]) {
        self.currentItem = currentItem
        self.appState = appState
        self.seasons = seasons
    }
    
    @MainActor
    func fetch() async {
        guard self.isLoaded == false else { return }
        do {
            let (server, token, userID) = try appState.get()
            
            async let itemDetail = apiClient.fetchItemDetail(server: server, userID: userID, token: token, of: currentItem)
            async let seasonItems = apiClient.fetchItems(server: server, userID: userID, token: token, of: currentItem)
            
            currentItem = try await itemDetail
            let fetchedSeasons = try await seasonItems.map { SeriesInfo(season: $0) }
            seasons = fetchedSeasons  // 直接代入
            
            await fetchSeasons(seasons: fetchedSeasons)  // `seasons` を渡して更新
        } catch {
            print(error)
        }
    }
    
    /// 各シーズンのエピソードを取得
    @MainActor
    private func fetchSeasons(seasons: [SeriesInfo]) async {
        do {
            let (server, token, userID) = try appState.get()

            // **各シーズンのエピソードを並列取得**
            let seasonResults = try await withThrowingTaskGroup(of: (Int, SeriesInfo).self) { group -> [SeriesInfo] in
                for (index, seasonInfo) in seasons.enumerated() {
                    group.addTask {
                        let episodes = try await self.apiClient.fetchItems(server: server, userID: userID, token: token, of: seasonInfo.season)
                        let updatedEpisodes = await self.fetchEpisodes(for: episodes, server: server, userID: userID, token: token)

                        let newSeason = SeriesInfo(season: seasonInfo.season, episodes: updatedEpisodes)
                        return (index, newSeason)
                    }
                }

                var updatedSeasons = seasons
                for try await (index, updatedSeason) in group {
                    updatedSeasons[index] = updatedSeason
                }
                return updatedSeasons
            }
            self.seasons = seasonResults
            self.seasons.forEach { $0.sortEpisodes() }
            self.isLoaded = true
        } catch {
            print(error)
        }
    }
    
    /// 各エピソードの詳細を取得
    @MainActor
    private func fetchEpisodes(for episodes: [BaseItem], server: String, userID: String, token: String) async -> [BaseItem] {
        do {
            return try await withThrowingTaskGroup(of: BaseItem.self) { group -> [BaseItem] in
                for episode in episodes {
                    group.addTask {
                        return try await self.apiClient.fetchItemDetail(server: server, userID: userID, token: token, of: episode)
                    }
                }
                
                var detailedEpisodes: [BaseItem] = []
                for try await detailedEpisode in group {
                    detailedEpisodes.append(detailedEpisode)
                }
                return detailedEpisodes
            }
        } catch {
            print(error)
            return episodes
        }
    }
}

struct EpisodeView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var season: SeriesInfo
    
    let episode: BaseItem
    let width: CGFloat
    @State private var isExpanded = false
    
    func nextMoviePreview(item: BaseItem) -> some View {
        let controller = MoviePreviewController(currentItem: item, appState: appState)
        return MoviePreview(controller: controller).environmentObject(appState)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
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
                    .frame(width: width * 0.2, height: width * 0.2 / 16 * 9)
                    .cornerRadius(8)
                }

                // 再生ボタン（画像の中央に重ねる）
                NavigationLink(destination: nextMoviePreview(item: episode)) {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width * 0.2 * 0.3, height: width * 0.2 * 0.3)
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }
            }
            VStack(alignment: .leading) {
                NavigationLink(destination: nextMoviePreview(item: episode)) {
                    if let indexNumber = episode.indexNumber {
                        Text("\(indexNumber). \(episode.name)")
                            .font(.title)
                            .foregroundColor(.black)
                    } else {
                        Text(episode.name)
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                
                if let overview = episode.overview {
                    Text(overview)
                    .lineLimit(isExpanded ? nil : 3)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black)
                    .onTapGesture {
                        isExpanded.toggle()
                    }
                    .animation(.easeInOut, value: isExpanded)
                } else {
                }
                Spacer()
            }
            .frame(height: width * 0.2 / 16 * 9)
        }
        .padding(.horizontal, 10)
    }
}

struct EpisodeSmallView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var season: SeriesInfo
    
    let episode: BaseItem
    let width: CGFloat
    @State private var isExpanded = false
    
    func nextMoviePreview(item: BaseItem) -> some View {
        let controller = MoviePreviewController(currentItem: item, appState: appState)
        return MoviePreview(controller: controller).environmentObject(appState)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
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
                    .cornerRadius(8)
                }

                // 再生ボタン（画像の中央に重ねる）
                NavigationLink(destination: nextMoviePreview(item: episode)) {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width * 0.3, height: width * 0.3)
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }
            }
            
            NavigationLink(destination: nextMoviePreview(item: episode)) {
                VStack(alignment: .leading) {
                    if let indexNumber = episode.indexNumber {
                        Text("\(indexNumber). \(episode.name)")
                            .font(.title)
                            .foregroundColor(.black)
                    } else {
                        Text(episode.name)
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    
                    if let overview = episode.overview {
                        Text(verbatim: overview)
                        .lineLimit(isExpanded ? nil : 3)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black)
                        .onTapGesture {
                            isExpanded.toggle()
                        }
                        .animation(.easeInOut, value: isExpanded)
                    } else {
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 10)
    }
}

struct SeasonView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var season: SeriesInfo
    let width: CGFloat
    let hidesSeasonTitle: Bool
    
    func nextMoviePreview(item: BaseItem) -> some View {
        let controller = MoviePreviewController(currentItem: item, appState: appState)
        return MoviePreview(controller: controller).environmentObject(appState)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            if !hidesSeasonTitle {
                Text(season.season.name)
                    .font(.title)
                    .bold()
            }
            ForEach(season.episodes, id: \.id) { episode in
                if UIDevice.current.userInterfaceIdiom == .phone {
                    EpisodeSmallView(season: season, episode: episode, width: width).environmentObject(appState)
                } else {
                    EpisodeView(season: season, episode: episode, width: width).environmentObject(appState)
                }
            }
        }
        .padding(.bottom, 40)
    }
}

struct SeriesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var contentModel: SeriesViewController

    init(controller: SeriesViewController) {
        _contentModel = StateObject(wrappedValue: controller)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        Text(contentModel.currentItem.overview ?? "")
                        ForEach(contentModel.seasons) { season in
                            SeasonView(season: season, width: proxy.size.width, hidesSeasonTitle: (contentModel.seasons.count <= 1)).environmentObject(appState)
                        }
                    }
                    .padding(.top)
                    .padding(.horizontal)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            print("onAppear")
            Task {
                await contentModel.fetch()
            }
        }
        .navigationTitle(Text(contentModel.currentItem.name))
    }
}

#Preview {
    let appState = AppState(server: "https://example.com", token: "token", userID: "1", isAuthenticated: true)
    let con = SeriesViewController(currentItem: BaseItem.dummy, appState: appState, seasons: [SeriesInfo.dummy, SeriesInfo.dummy, SeriesInfo.dummy])
    SeriesView(controller: con).environmentObject(appState)
}
