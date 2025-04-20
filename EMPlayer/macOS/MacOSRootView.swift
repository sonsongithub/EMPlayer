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
    
    let apiClient = APIClient()
    
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
        
        guard let serverName = selectedServer?.address else { return }
        
        print(serverName)
        
        Task {
            do {
                print("try")
                print(username)
                print(password)
                let authenticationResponse = try await self.apiClient.login(server: serverName, username: username, password: password)
                print(authenticationResponse)
                let account = Account(serverAddress: serverName, username: authenticationResponse.user.name, userID: authenticationResponse.user.id, token: authenticationResponse.accessToken)
                print(account)
                DispatchQueue.main.async {
                    print("try2")
                    self.accountManager.saveAccount(account)
                    self.appState.isAuthenticated = true
                    self.appState.userID = account.userID
                    self.appState.server = account.serverAddress
                    self.appState.token = account.token
//                    self.isLoading = false
//                    self.errorMessage = nil
                    self.selectedServer = nil
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
//                    self.isLoading = false
//                    self.errorMessage = error.localizedDescription
                    self.selectedServer = nil
                }
            }
        }
    }
}


class LeftPaneRootViewController: ObservableObject {
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

struct LeftPane: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    
    @StateObject var controller: LeftPaneRootViewController
    
    @State private var selectedServer: ServerInfo? = nil
    @State private var showingLoginSheet = false
    
    let apiClient = APIClient()
    
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
                                        let user = try await self.apiClient.getUserInfo(server: account.serverAddress, userID: account.userID, token: account.token)
                                        if user.id == account.userID {
                                            appState.server = account.serverAddress
                                            appState.token = account.token
                                            appState.userID = account.userID
                                            appState.isAuthenticated = true
                                        } else {
                                        //    showErrorAlert = true
                                        }
                                    } catch {
                                        //showErrorAlert = true
                                        print(error)
                                    }
                                }
                            }
                        }
                    }
                }
                if appState.isAuthenticated {
                    Section(header: Text("Current Server")) {
                        ForEach(controller.items, id: \.id) { item in
                            Button(item.name) {
                                // Handle item selection
                                print("Selected item: \(item.name)")
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
        .onChange(of: appState.server) { _ in
            if appState.isAuthenticated {
                Task {
                    await controller.fetch()
                }
            }
        }
        // load content appstate is authenticated
        .onChange(of: appState.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                Task {
                    await controller.fetch()
                }
            }
        }
    }
}

struct RightPane: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Text("Right Pane")
        }
    }
}

struct MacOSRootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    
    @StateObject var rootViewController: MacOSRootViewController
    
    @State private var showVideoPlayer = false
  
    var body: some View {
        ZStack {
            HSplitView {
                LeftPane(controller: LeftPaneRootViewController(appState: appState))
                    .environmentObject(appState)
                    .environmentObject(accountManager)
                    .environmentObject(serverDiscovery)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listStyle(.sidebar)
                RightPane()
                    .environmentObject(appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listStyle(.sidebar)
            }
    
            // 動画プレイヤーのオーバーレイ
            if showVideoPlayer {
                VStack(alignment: .center) {
                    Text("Video Player")
                    Button("Close") {
                        showVideoPlayer = false
                    }
                }
            }
        }
    }
}

#Preview {
    let appState = AppState(server: "https://example.com", token: "token", userID: "1", isAuthenticated: true)
    let controller = MacOSRootViewController(appState: appState)
    MacOSRootView(rootViewController: controller).environmentObject(appState)
}
    
#endif

