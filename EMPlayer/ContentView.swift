//
//  ContentView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var showAuthModal = false
    
    @ObservedObject private var loader = MovieLoader()
    
    @State private var path = NavigationPath()
    
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
            List(loader.movies, id: \.id) { movie in
                NavigationLink(destination: nextView(item: movie).environmentObject(appState)) { HStack {
                    if let url = movie.imageURL(server: appState.server!) {
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
                    
                    // 名前を表示
                    Text(movie.name)
                        .font(.headline)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                }
        }
        .navigationTitle("Top")
        .navigationBarBackButtonHidden(false)
            .sheet(isPresented: $showAuthModal) {
                AuthFlowView().environmentObject(appState)
            }
            .onAppear {
                if self.appState.ready {
                    fetchContent()
                } else {
                    showAuthModal = true
                }
            }
            .onChange(of: appState.userID) { newValue in
                print("userID updated")
                if appState.ready {
                    print("a")
                    if let server = self.appState.server, let token = self.appState.token, let userID = appState.userID {
                        loader.login(server: server, token: token, userID: userID) { success, hoge in
                            print("ok?")
                        }
                    }
                }
            }
        }
    }
    
    func fetchContent() {
        if appState.ready {
            print("a")
            if let server = self.appState.server, let token = self.appState.token, let userID = appState.userID {
                loader.login(server: server, token: token, userID: userID) { success, hoge in
                    print("ok?")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
