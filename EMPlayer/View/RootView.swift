//
//  RootView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/03.
//

import SwiftUI

class RootViewController: ObservableObject {
    let appState: AppState
    private let apiClient = APIClient()
    
    @Published var items: [BaseItem] = []
    
    init(appState: AppState) {
        self.appState = appState
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.items = [BaseItem.dummy, BaseItem.dummy, BaseItem.dummy, BaseItem.dummy, BaseItem.dummy, BaseItem.dummy]
        }
    }
    
    @MainActor
    func fetch() async {
        do {
            let (server, token, userID) = try appState.get()
            self.items = try await apiClient.fetchUserView(server: server, userID: userID, token: token)
        } catch {
            self.appState.logout()
            print(error)
        }
    }
    
}

struct RootViewItemView: View {
    let item: BaseItem
    let appState: AppState
    let width = CGFloat(200)
    let height = CGFloat(150)
    var body: some View {
        GeometryReader { geometry in
            NavigationLink(destination: item.nextView(appState: appState)) {
                HStack {
                    if let url = item.imageURL(server: appState.server) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 150)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 200, height: 150)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 150)
                            .foregroundColor(.gray)
                    }
                    Text(item.name)
                        .font(.title2)
                        .dynamicTypeSize(.xSmall)
                }.padding(.vertical, 5)
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewController: RootViewController
    @State private var showAuthSheet = false
    
    init(rootViewController: RootViewController) {
        _viewController = StateObject(wrappedValue: rootViewController)
    }
    
    var body: some View {
        NavigationStack {
            List(viewController.items, id: \.id) { item in
                RootViewItemView(item: item, appState: appState).frame(height: 150)
            }.onAppear {
                showAuthSheet = !appState.isAuthenticated
                Task {
                    await viewController.fetch()
                }
            }
            .sheet(isPresented: $showAuthSheet) {
                AuthenticationView(isPresented: $showAuthSheet).environmentObject(appState).interactiveDismissDisabled(true)
            }
            .onChange(of: appState.isAuthenticated) {
                showAuthSheet = !appState.isAuthenticated
                if appState.isAuthenticated {
                    Task {
                        await viewController.fetch()
                    }
                }
            }
            .navigationTitle(appState.server ?? "")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        appState.isAuthenticated = false
                    }) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
        
    }
}

#Preview {
    let appState = AppState(server: "https://example.com", token: "token", userID: "1", isAuthenticated: true)
    let rootViewController = RootViewController(appState: appState)
    RootView(rootViewController: rootViewController).environmentObject(appState)
}
