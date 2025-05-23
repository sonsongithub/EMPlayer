//
//  AuthenticationSubView.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/29.
//

import SwiftUI

#if os(macOS)

//struct SidebarView: View {
//    @EnvironmentObject var appState: AppState
//    @EnvironmentObject var accountManager: AccountManager
//    @EnvironmentObject var authService: AuthService
//    @EnvironmentObject var itemRepository: ItemRepository
//    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
//    @EnvironmentObject var drill: DrillDownStore
//
//    var body: some View {
//    }
//}

struct AuthenticationSubView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var drill: DrillDownStore
    
    @State private var selectedServer: ServerInfo? = nil
    @State private var showLoginSheet = false
    
    var serversHeader: some View {
        HStack {
            Text("Servers")
            Button {
                showLoginSheet = true
            } label: {
                Image(systemName: "plus").frame(width: 4, height: 4)
            }
            Spacer()
        }
    }
    
    var historyHeader: some View {
        HStack {
            Text("History")
            Button {
                showLoginSheet = true
            } label: {
                Image(systemName: "trash").frame(width: 4, height: 4)
            }
            Spacer()
        }
    }
    
    var rootView: some View {
        Group {
            if let root = drill.root {
                Section(header: Text("Root")) {
                    ForEach(root.children) { child in
                        Text(child.display())
                            .onTapGesture {
                                Task { await open(child, from: -1) }
                            }
                    }
                }
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: serversHeader) {
                ForEach(serverDiscovery.servers, id: \.self) { server in
                    Text(server.name)
                        .onTapGesture {
                            self.selectedServer = server
                        }
                }
            }
            Section(header: historyHeader) {
                ForEach(accountManager.names, id: \.self) { name in
                    Text(accountManager.displayName(for: name))
                        .onTapGesture {
                            if let account = accountManager.accounts[name] {
                                self.appState.isAuthenticated = true
                                self.appState.userID = account.userID
                                self.appState.server = account.server
                                self.appState.token = account.token
                                self.selectedServer = nil
                                self.drill.reset()
                            }
                        }
                }
            }
            rootView
        }
        .sheet(isPresented: $showLoginSheet) {
                    LoginToServerView()
                        .environmentObject(appState)
                        .environmentObject(accountManager)
                        .environmentObject(serverDiscovery)
                        .environmentObject(itemRepository)
                        .environmentObject(authService)
                        .environmentObject(drill)
                }
        .sheet(item: $selectedServer) { server in
            LoginSheetView(selectedServer: $selectedServer)
                .environmentObject(appState)
                .environmentObject(accountManager)
                .environmentObject(itemRepository)
                .environmentObject(authService)
                .environmentObject(drill)
        }
    }
    // タップ時
    @MainActor
    private func open(_ child: ItemNode, from level: Int) async {
        // ① deeper or play
        switch child.item {
        case .series(let base), .collection(let base), .boxSet(let base):
            Task {
                let items = try await itemRepository.children(of: base)
                print("items: \(items.count)")
                let children = items.map({ ItemNode(item: $0)})
                DispatchQueue.main.async {
                    drill.stack = Array(drill.stack.prefix(level + 1))
                    drill.push(ItemNode(item: nil, children: children))
                }
            }
        case .season(let base):
            drill.detail = ItemNode(item: base)
        case .movie(let base):
            drill.detail = ItemNode(item: base)
        case .episode(let base):
            drill.detail = ItemNode(item: base)
        default:
            drill.detail = child
        }
    }
}

#endif
