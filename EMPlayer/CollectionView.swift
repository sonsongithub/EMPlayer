//
//  CollectionView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

//def item_detail(item_id, server=EMBY_SERVER, api_key=API_KEY, user_id=USER_ID):
//    url = f"{server}/Users/{user_id}/Items/{item_id}"
//    headers = {"X-Emby-Token": api_key}
//    
//    response = requests.get(url, headers=headers)
//    
//    if response.status_code == 200:
//        response_json = response.json()
//        return response_json
//    else:
//        raise Exception(f"Item {item_id} not found! Status: {response.status_code}")

class ContentsIncludingSome: ObservableObject {
    @Published var items: [BaseItem] = []
    
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
                urlComponents.queryItems?.append(URLQueryItem(name: "Recursive", value: "true"))
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
                    self.items = object.items
                    
                    print(self.items)
                    
                    for i in (0..<self.items.count) {
                        self.getDetailfuncGet(server: server, token: token, userID: userID, itemID: self.items[i].id) { success, item in
                            if let item = item {
                                self.items[i] = item
                            }
                        }
                    }
                    
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
//        if item.type == "CollectionFolder" || item.type == "BoxSet" || item.type == "Series" || item.type == "Season" {
        if item.type == .collectionFolder || item.type == .boxSet || item.type == .series || item.type == .season {
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
                    con.get(server: server, token: token, userID: userID, parentID: item.id, parent: item) { success, string in
                    }
                }
                    
            }
        }
    }
}
