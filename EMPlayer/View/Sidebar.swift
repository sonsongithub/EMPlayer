//
//  AuthenticationSubView.swift
//  EMPlayer
//
//  Created by sonson on 2025/04/29.
//

import SwiftUI

#if os(macOS)

struct Sidebar: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var drill: DrillDownStore
    
    @State private var selectedServer: ServerInfo? = nil
    @State private var showLoginSheet = false
    @State private var showAlert = false
    @State private var showErrorAlert = false
    
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
            ServerHistoryView {
                // didPushPlus
                showLoginSheet = true
            } didPushTrash: {
                // didPushTrash
                showAlert = true
            } didPushServer: { serverInfo in
                self.selectedServer = serverInfo
            } didPushHistory: { account in
                self.appState.isAuthenticated = true
                self.appState.userID = account.userID
                self.appState.server = account.server
                self.appState.token = account.token
                self.selectedServer = nil
                self.drill.reset()
            }
            .environmentObject(appState)
            .environmentObject(accountManager)
            .environmentObject(itemRepository)
            .environmentObject(serverDiscovery)
            .environmentObject(authService)
            .environmentObject(drill)
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
        .alert("Are you sure to delete your history?", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { accountManager.deleteAll() }
        } message: {
            Text("This operation cannot be undone.")
        }
    }
    
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
