//
//  CollectionView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

class ContentsIncludingSome: ObservableObject {
    @Published var items: [BaseItem] = []
    
    func get(server: String, token: String, userID: String, parentID: String, completion: @escaping (Bool, String?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Items") else {
            completion(false, nil)
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "ParentId", value: parentID)
        ]
        
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
                    self.items = object.items
                    completion(true, nil)
                } catch {
                    print(error)
                    completion(false, nil)
                }
            }
        }.resume()
    }
}

struct CollectionView: View {
    
    @EnvironmentObject var appState: AppState
    
    let item: BaseItem
    @ObservedObject var con = ContentsIncludingSome()
    
    init(item: BaseItem) {
        self.item = item
    }
    
    @ViewBuilder
    func nextView(item: BaseItem) -> some View {
        if item.type == "CollectionFolder" || item.type == "BoxSet" || item.type == "Series" || item.type == "Season" {
            CollectionView(item: item)
        } else {
            DetailView(movieID: item.id)
        }
    }
    
    var body: some View {
        NavigationStack {
            
            List(con.items, id: \.id) { item in
                NavigationLink(destination: nextView(item: item).environmentObject(appState)) {
                    HStack {
                        if let url = item.imageURL(server: appState.server!) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 150, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 150, height: 200)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 150, height: 200)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 200)
                            
                                .foregroundColor(.gray)
                        }
                        VStack {
                            Text(item.name)
                            Text(item.overview ?? "")
                        }
                    }
                }
            }
            .navigationTitle(item.name)
            .navigationBarBackButtonHidden(false)
            .onAppear {
                
                if let server = appState.server, let userID = appState.userID, let token = appState.token {
                    con.get(server: server, token: token, userID: userID, parentID: item.id) { success, string in
                    }
                }
                    
            }
        }
    }
}
