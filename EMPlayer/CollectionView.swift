//
//  CollectionView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

class ContentsIncludingSome: ObservableObject {
    @Published var items: [BaseItem] = []
    
    static func forPreivew() -> ContentsIncludingSome {
        let con = ContentsIncludingSome()
        for _ in (0..<20) {
            con.items.append(BaseItem.dummy)
        }
        return con
    }
    
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
    
    let minWidth: CGFloat = 60  // カラムの最小幅
    let maxWidth: CGFloat = 150  // カラムの最大幅
    let horizontalSpacing: CGFloat = 16
    
    
    let itemPerRow: CGFloat = 8
    
    @EnvironmentObject var appState: AppState
    
    let item: BaseItem
    @ObservedObject var con = ContentsIncludingSome()
    
    init(item: BaseItem) {
        self.item = item
    }
    
    init(con: ContentsIncludingSome) {
        self.item = BaseItem.dummy
        self.con = con
    }
     
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let itemPerRow = max(1, Int(availableWidth / maxWidth))
                let columnWidth = max(minWidth, (availableWidth - (horizontalSpacing * CGFloat(itemPerRow + 1))) / CGFloat(itemPerRow))
                let height = floor(columnWidth * 10.0 / 7.0 + 10)
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        let rows = self.con.items.chunked(into: itemPerRow)
                        ForEach(rows.indices, id: \.self) { rowIndex in
                            RowView(appState: appState, items: rows[rowIndex], width: columnWidth, height: height, horizontalSpacing: horizontalSpacing)
                        }
                        Spacer()
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
        
            if let server = appState.server, let userID = appState.userID, let token = appState.token {
                con.get(server: server, token: token, userID: userID, parentID: item.id, parent: item) { success, string in
                }
            }
        
        }
        .navigationTitle(item.name)
    }
}

struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionView(con: ContentsIncludingSome.forPreivew()).environmentObject(AppState())
    }
}
