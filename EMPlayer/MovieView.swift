//
//  MovieView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

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

import SwiftUI


class MovieDetailLoader : ObservableObject {
    
    @Published var movies: [MovieInfo] = []
    
    func login(server: String, userID: String, token: String, itemID: String, completion: @escaping (Bool, URL?) -> Void) {
        // Users/{user_id}/Items/{item_id}
        guard var urlComponents = URLComponents(string: "\(server)/Users/\(userID)/Items/\(itemID)") else {
            completion(false, nil)
            return
        }
        
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
            
            do {
//                // json
                if let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
//                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
////                    print(json)
//                }
                
                let decoder = JSONDecoder()
                let object = try decoder.decode(PlayableItem.self, from: data)
                print(object)
                
                let baseItem = BaseItem(item: object)
                
                if let url = baseItem.playableVideo(from: server) {
//                    print(url)
                    completion(true, url)
                    return
                }
                
                completion(false, nil)
            } catch {
                completion(false, nil)
            }
        }.resume()
    }
    
}

import AVKit

struct DetailView: View {
    @StateObject private var appState = AppState()
    
    let con = MovieDetailLoader()
    
    var movieID: String
    
    @State var url: URL?
    @State var asset: AVURLAsset?
    
//    private let player = AVPlayer(url: Bundle.main.url(forResource: "river", withExtension: "mp4")!)
    
    var body: some View {
        VStack {
            if asset == nil {
                Text("wait...")
            } else {
                VideoPlayer(player: AVPlayer(playerItem: AVPlayerItem(asset: asset!)))
            }
        }.onAppear {
            print(movieID)
            if let server = appState.server, let userID = appState.userID, let token = appState.token {
                con.login(server: server, userID: userID, token: token, itemID: movieID) { success, hoge in
                    if success {
                        if let url = hoge {
                            let headers = ["X-Emby-Token": token]
                            self.asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey" : headers])
                        }
                    }
                }
            }
        }
    }
}
