//
//  SeriesView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/23.
//

import SwiftUI

class EmbySeriesModel : ObservableObject {
    var own: BaseItem?
    
    @Published var seasons: [BaseItem] = []
    
    func get2(server: String, token: String, userID: String, parentID: String, parent: BaseItem, completion: @escaping (Bool, String?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Items") else {
            completion(false, nil)
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "ParentId", value: parentID)
            
        ]
        
        if let collectionType = parent.collectionType {
            if collectionType == .movies {
//                urlComponents.queryItems?.append(URLQueryItem(name: "Recursive", value: "true"))
                urlComponents.queryItems?.append(URLQueryItem(name: "IncludeItemTypes", value: "Movie"))
            }
        }
        
//        urlComponents.queryItems?.append(URLQueryItem(name: "Recursive", value: "true"))
        
        guard let url = urlComponents.url else {
            completion(false, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("start")
            if let error = error {
                print(error)
                completion(false, nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                print("http response error")
                completion(false, nil)
                return
            }
            DispatchQueue.main.async {
                let decoder = JSONDecoder()
                do {
                    let object = try decoder.decode(QueryResult<BaseItem>.self, from: data)
                    print(object)
                    self.seasons = object.items
                    print(self.seasons.count)
                    completion(true, nil)
                } catch {
                    print(error)
                    completion(false, nil)
                }
            }
        }.resume()
    }
}

class EmbySeasonModel : ObservableObject {
    var own: BaseItem?
    
    @Published var episodes: [BaseItem] = []
    
    func getDetailfuncGet(server: String, token: String, userID: String, itemID: String, completion: @escaping (Bool, BaseItem?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Items/\(itemID)") else {
            completion(false, nil)
            return
        }
        
//        urlComponents.queryItems?.append(URLQueryItem(name: "Recursive", value: "true"))
        
        guard let url = urlComponents.url else {
            completion(false, nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
                completion(false, nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                print("http response error")
                completion(false, nil)
                return
            }
            DispatchQueue.main.async {
                let decoder = JSONDecoder()
                do {
                    let object = try decoder.decode(BaseItem.self, from: data)
//                    print(object)
                    completion(true, object)
                } catch {
                    print(error)
                    completion(false, nil)
                }
            }
        }.resume()
    }
    
    
    func get(server: String, token: String, userID: String, parentID: String, parent: BaseItem, completion: @escaping (Bool, String?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Items") else {
            completion(false, nil)
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "ParentId", value: parentID)
            
        ]
        
        if let collectionType = parent.collectionType {
            if collectionType == .movies {
//                urlComponents.queryItems?.append(URLQueryItem(name: "Recursive", value: "true"))
                urlComponents.queryItems?.append(URLQueryItem(name: "IncludeItemTypes", value: "Movie"))
            }
        }
        
        guard let url = urlComponents.url else {
            completion(false, nil)
            return
        }
        
        print("------------------------------------------------------------")
        print(parent.name)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("start")
            if let error = error {
                print(error)
                completion(false, nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                print("http response error")
                print("------------------------------------")
                print(self.own?.type)
                print(request.url)
                completion(false, nil)
                return
            }
            DispatchQueue.main.async {
                let decoder = JSONDecoder()
                do {
                    let object = try decoder.decode(QueryResult<BaseItem>.self, from: data)
                    self.episodes = object.items
                    
                    for i in (0..<self.episodes.count) {
                        self.getDetailfuncGet(server: server, token: token, userID: userID, itemID: self.episodes[i].id) { success, item in
                            if let item = item {
                                self.episodes[i] = item
                            }
                        }
                    }
                    
                } catch {
                    print(error)
                    completion(false, nil)
                }
            }
        }.resume()
    }
            
}

struct HorizontalSeasonView: View {
    @EnvironmentObject var appState: AppState
    
    let season: BaseItem
    @ObservedObject var contentModel = EmbySeasonModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer(minLength: 100)
            Text(season.name)
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
                contentModel.own = season
                
                if let server = appState.server, let token = appState.token, let userID = appState.userID {
                    contentModel.get(server: server, token: token, userID: userID, parentID: self.season.id, parent: self.season) { success, string in
                        // update seasons
                    }
                }
            }
        }
    }
}

//struct HorizontalSeasonView_Previews: PreviewProvider {
//    static var previews: some View {
//        ScrollView {
//            VStack {
//                HorizontalSeasonView(season: BaseItem.dummy)
//                HorizontalSeasonView(season: BaseItem.dummy)
//                HorizontalSeasonView(season: BaseItem.dummy)
//            }
//        }
//    }
//}

struct SeriesView: View {
    @EnvironmentObject var appState: AppState
    let series: BaseItem
    
    @ObservedObject var contentModel = EmbySeriesModel()
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                ForEach(contentModel.seasons, id: \.id) { season in
                    HorizontalSeasonView(season: season)
                        .environmentObject(appState)
                }
            }
        }
        .onAppear {
            
            contentModel.own = series
            if let server = appState.server, let token = appState.token, let userID = appState.userID {
                contentModel.get2(server: server, token: token, userID: userID, parentID: series.id, parent: self.series) { success, string in
                    // update seasons
                }
            }
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

#Preview {
    let appState = AppState(server: "https://example.com", token: "token", userID: "1", isAuthenticated: true)
    SeriesView(series: BaseItem.dummy).environmentObject(appState)
//    HorizontalSeasonEpisodeView(item: BaseItem.dummy).environmentObject(appState)
//        .border(.red)
//        .frame(width: 400, height: 350)
}
