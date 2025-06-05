//
//  ServerHistoryView.swift
//  EMPlayer
//
//  Created by sonson on 2025/05/24.
//


import SwiftUI

struct ServerHistoryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var accountManager: AccountManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var serverDiscovery: ServerDiscoveryModel
    @EnvironmentObject var drill: DrillDownStore
    
    let didPushPlus: () -> Void
    let didPushTrash: () -> Void
    let didPushServer: (_: ServerInfo) -> Void
    let didPushHistory: (_: Account) -> Void
    
    var serversHeader: some View {
        HStack {
            Text("Servers")
            Button {
                self.didPushPlus()
            } label: {
                Image(systemName: "plus").font(.system(size: 12))
            }
            Spacer()
        }
    }
    
    var historyHeader: some View {
        HStack {
            Text("History")
            Button {
                self.didPushTrash()
            } label: {
                Image(systemName: "trash").font(.system(size: 12))
            }
            Spacer()
        }
    }
    
    var body: some View {
        Group {
            Section(header: serversHeader) {
                ForEach(serverDiscovery.servers, id: \.self) { server in
#if os(macOS) || os(iOS)
                    Text(server.name)
                        .onTapGesture {
                            self.didPushServer(server)
                        }
#elseif os(tvOS)
                    Button(server.name) {
                        self.didPushServer(server)
                    }
#endif
                }
            }
            Section(header: historyHeader) {
                ForEach(accountManager.names, id: \.self) { name in
#if os(macOS) || os(iOS)
                    Text(accountManager.displayName(for: name))
                        .onTapGesture {
                            if let account = accountManager.accounts[name] {
                                self.didPushHistory(account)
                            }
                        }
#elseif os(tvOS)
                    Button(accountManager.displayName(for: name)) {
                        if let account = accountManager.accounts[name] {
                            self.didPushHistory(account)
                        }
                    }
#endif
                }
            }
        }
    }
}