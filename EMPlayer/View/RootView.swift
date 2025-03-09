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
    }
    
    @MainActor
    func fetch() async {
        do {
            let (server, token, userID) = try appState.get()
            self.items = try await apiClient.fetchUserView(server: server, userID: userID, token: token)
        } catch {
            print(error)
        }
    }
    
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: RootViewController
    @State private var showAuthSheet = false
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: RootViewController(appState: appState))
    }
    
    var body: some View {
        NavigationStack {
            List(viewModel.items, id: \.id) { item in
                Text(item.name)
            }.onAppear {
                showAuthSheet = !appState.isAuthenticated
                Task {
                    await viewModel.fetch()
                }
            }
            .sheet(isPresented: $showAuthSheet) {
                AuthenticationView(isPresented: $showAuthSheet).environmentObject(appState).interactiveDismissDisabled(true)
            }
            .onChange(of: appState.isAuthenticated) {
                showAuthSheet = !appState.isAuthenticated
                if appState.isAuthenticated {
                    Task {
                        await viewModel.fetch()
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
    RootView(appState: appState).environmentObject(appState)
}
