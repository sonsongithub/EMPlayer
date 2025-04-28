//
//  MacOSRootView.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/19.
//

import SwiftUI

#if os(macOS)

class MacOSRootViewController: ObservableObject {
    let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
    }
}

struct LoginSheetView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var itemRepository: ItemRepository
    
//    let apiClient = APIClient()
    
    @Binding var selectedServer: ServerInfo?
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login to \(self.selectedServer?.address)")
                .font(.headline)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    self.selectedServer = nil
                }
                Spacer()
                Button("Login") {
                    self.login()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 400)
    }
    
    func login() {
        
        guard let server = selectedServer?.address else { return }

        
        Task {
            do {
                let authenticationResponse = try await authService.login(server: server, user: username, pass: password)
                
                let user = try await itemRepository.userInfo()
                
                let account = Account(server: server, username: user.name, userID: user.id, token: authenticationResponse.accessToken)
                DispatchQueue.main.async {
                    self.accountManager.saveAccount(account)
                    self.appState.isAuthenticated = true
                    self.appState.userID = account.userID
                    self.appState.server = account.server
                    self.appState.token = account.token
                    self.selectedServer = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.selectedServer = nil
                }
                print(error)
            }
        }
        
            
        
        
//        guard let serverName = selectedServer?.address else { return }
//        Task {
//            do {
//                let authenticationResponse = try await self.apiClient.login(server: serverName, username: username, password: password)
//                let account = Account(server: serverName, username: authenticationResponse.user.name, userID: authenticationResponse.user.id, token: authenticationResponse.accessToken)
//                DispatchQueue.main.async {
//                    self.accountManager.saveAccount(account)
//                    self.appState.isAuthenticated = true
//                    self.appState.userID = account.userID
//                    self.appState.server = account.server
//                    self.appState.token = account.token
////                    self.isLoading = false
////                    self.errorMessage = nil
//                    self.selectedServer = nil
//                }
//            } catch {
//                DispatchQueue.main.async {
////                    self.isLoading = false
////                    self.errorMessage = error.localizedDescription
//                    self.selectedServer = nil
//                }
//            }
//        }
    }
}

class LeftPaneRootViewController: ObservableObject {
    let appState: AppState
//    private let apiClient = APIClient()
    
    @Published var items: [BaseItem] = []
    
    init(appState: AppState) {
        self.appState = appState
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.items = [BaseItem.dummy, BaseItem.dummy, BaseItem.dummy, BaseItem.dummy, BaseItem.dummy, BaseItem.dummy]
        }
    }
    
    @MainActor
    func fetch() async {
//        do {
//            let (server, token, userID) = try appState.get()
//            self.items = try await apiClient.fetchUserView(server: server, userID: userID, token: token)
//        } catch {
//            self.appState.logout()
//            print(error)
//        }
    }
    
    @MainActor
    func getUserInfo(account: Account) async throws {
//        let user = try await self.apiClient.getUserInfo(server: account.server, userID: account.userID, token: account.token)
//        
//        if user.id == account.userID {
//            appState.server = account.server
//            appState.token = account.token
//            appState.userID = account.userID
//            appState.isAuthenticated = true
//        } else {
//            throw APIClientError.invalidUser
//        }
    }
}

struct LeftPane: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var router: PaneRouter
    
    @StateObject var controller: LeftPaneRootViewController
    
    @State private var selectedServer: ServerInfo? = nil
    @State private var showingLoginSheet = false
    
    @State private var searchQuery: String = ""
    
//    let apiClient = APIClient()
    
    init(controller: LeftPaneRootViewController) {
        print("init LeftPane")
        _controller = StateObject(wrappedValue: controller)
    }
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Servers")) {
                    ForEach(serverDiscovery.servers, id: \.self) { server in
                        Button(action: {
                            self.selectedServer = server
                        }) {
                            Text(server.name)
                        }
                    }
                }
                Section(header: Text("History")) {
                    ForEach(accountManager.names, id: \.self) { name in
                        Button(accountManager.displayName(for: name)) {
                            if let account = accountManager.accounts[name] {
                                Task {
                                    do {
                                        try await controller.getUserInfo(account: account)
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                    }
                }
                if appState.isAuthenticated {
                    Section(header: Text("Current Server")) {
                        HStack {
                                Image(systemName: "magnifyingglass")
                                TextField("検索...", text: $router.searchQuery)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        if router.searchQuery != nil {
//                                            Task {
//                                            
//                                                do {
//                                                    let (server, token, userID) = try self.appState.get()
//                                                    let items = try await self.apiClient.searchItem(server: server, userID: userID, token: token, query: router.searchQuery)
//                                                    DispatchQueue.main.async {
//                                                        self.router.rightState = .searchResults(items)
//                                                    }
//                                                } catch {
//                                                    print(error)
//                                                }
//                                            }
                                        }
                                    }
                                    
                            }
                        ForEach(controller.items, id: \.id) { item in
                            Button(item.name) {
                                print(item.name)
                                self.router.rightState = .detail(item)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedServer) { server in
            LoginSheetView(selectedServer: $selectedServer)
                .environmentObject(appState)
                .environmentObject(accountManager)
                .frame(minWidth: 400, minHeight: 300)
        }
        .onChange(of: appState.server) {
            if appState.isAuthenticated {
                Task {
                    await controller.fetch()
                }
            }
        }
        // load content appstate is authenticated
        .onChange(of: appState.isAuthenticated) {
            if appState.isAuthenticated {
                Task {
                    await controller.fetch()
                }
            }
        }.frame(maxWidth: 400)
    }
}

class SearchResultViewController: ObservableObject {
    let appState: AppState
    
//    let client = APIClient()
    
    @Published var items: [BaseItem] = []
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    @MainActor
    func fetch() async {
    }
}

struct SearchResultView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var controller: SearchResultViewController
    @EnvironmentObject var router: PaneRouter
    
    var body: some View {
        switch router.rightState {
        case .empty:
            Text("No search results")
        case .searchResults(let items):
            ForEach(items, id: \.id) { item in
                Button(item.name) {
                    // Handle item selection
                    print("Selected     : \(item.name)")
                }
            }
        default:
            Text("Unknown state")
        }
    }
}

final class PaneRouter: ObservableObject {
    @Published var rightState: RightPaneState = .empty
    @Published var searchQuery: String = ""      // 入力された検索語
}

class ItemListViewController: ObservableObject {
    let appState: AppState
//    let client = APIClient()
    
    let item: BaseItem
    
    @Published var items: [BaseItem] = []
    
    init(appState: AppState, item: BaseItem) {
        self.appState = appState
        self.item = item
    }
    
    @MainActor
    func fetch() async {
//        do {
//            let (server, token, userID) = try appState.get()
//            let items = try await client.fetchItems(server: server, userID: userID, token: token, of: self.item)
//            DispatchQueue.main.async {
//                self.items = items
//            }
//        } catch {
//            print(error)
//        }
    }
}

struct ItemListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: PaneRouter
    @EnvironmentObject var controller: ItemListViewController
    
    var body: some View {
        List {
            ForEach(controller.items, id: \.id) { item in
                Button(item.name) {
                    // Handle item selection
                    print("Selected     : \(item.name)")
                }
            }
        }
        .onChange(of: controller.item) {
            Task {
                print("fetch")
                await controller.fetch()
            }
        }
        .onAppear {
            Task {
                print("fetch")
                await controller.fetch()
            }
        }
    }
}

final class ItemNode: ObservableObject, Identifiable {
    let item: BaseItem
    @Published var children: [ItemNode]?
    @Published var isLoading = false
    @Published var loadError: Error? = nil
    
    init(item: BaseItem, children: [ItemNode]? = nil) {
        self.item = item
        self.children = children
    }
}

struct RightPane: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: PaneRouter
    @EnvironmentObject var repository: ItemRepository

    var body: some View {
        if appState.isAuthenticated {
            switch router.rightState {
            case .empty:
                Text("Please select a server.")
            case .searchResults:
                VSplitView {
                    SearchResultView(controller: SearchResultViewController(appState: appState)).environmentObject(appState)
                }
            case .detail(let item):
                ItemListView()
                    .environmentObject(ItemListViewController(appState: appState, item: item))
                    .environmentObject(appState)
                    .environmentObject(router)
            }
        } else {
            Text("Please login to a server.")
        }
    }
}

struct MacOSRootView: View {
    let roughter: PaneRouter = PaneRouter()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var itemRepository: ItemRepository
    @StateObject var rootViewController: MacOSRootViewController
    @EnvironmentObject var authService: AuthService
    
    @State private var showVideoPlayer = false
    @State private var selectedServer: ServerInfo? = nil
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Servers")) {
                    ForEach(serverDiscovery.servers, id: \.self) { server in
                        Button(action: {
                            self.selectedServer = server
                        }) {
                            Text(server.name)
                        }
                    }
                }
                Section(header: Text("History")) {
                    ForEach(accountManager.names, id: \.self) { name in
                        Button(accountManager.displayName(for: name)) {
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedServer) { server in
            LoginSheetView(selectedServer: $selectedServer)
                .environmentObject(appState)
                .environmentObject(accountManager)
                .environmentObject(itemRepository)
                .environmentObject(authService)
        }
        .onChange(of: appState.server) {
            if appState.isAuthenticated {
            }
        }
        // load content appstate is authenticated
        .onChange(of: appState.isAuthenticated) {
            if appState.isAuthenticated {
            }
        }
//        ZStack {
//            HSplitView {
//                LeftPane(controller: LeftPaneRootViewController(appState: appState))
//                    .environmentObject(appState)
//                    .environmentObject(accountManager)
//                    .environmentObject(serverDiscovery)
//                    .environmentObject(roughter)
//                    .frame(maxWidth: 400, maxHeight: .infinity)
//                    .listStyle(.sidebar)
//                RightPane()
//                    .environmentObject(appState)
//                    .environmentObject(roughter)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .listStyle(.sidebar)
//            }
//    
//            // 動画プレイヤーのオーバーレイ
//            if showVideoPlayer {
//                VStack(alignment: .center) {
//                    Text("Video Player")
//                    Button("Close") {
//                        showVideoPlayer = false
//                    }
//                }
//            }
//        }
    }
}

#Preview {
    let appState = AppState(server: "https://example.com", token: "token", userID: "1", isAuthenticated: true)
    let controller = MacOSRootViewController(appState: appState)
    MacOSRootView(rootViewController: controller).environmentObject(appState)
}
    
#endif

