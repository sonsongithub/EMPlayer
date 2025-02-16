//
//  ServerSelectionView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

struct ServerSelectionView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var selectedServer: String?
    @State private var navigateToLogin = false
    
    @ObservedObject var serverDiscovery = ServerDiscoveryModel()

    var body: some View {
        VStack {
            List(serverDiscovery.servers, id: \.self) { server in
                Button(server.name) {
                    appState.server = server.address
                    navigateToLogin = true
                    selectedServer = server.address
                }
                .padding()
            }
        }
        .navigationTitle("Select Server")
        .onAppear {
            
            serverDiscovery.sendBroadcastMessage()
        }.background(
            NavigationLink(
                destination: LoginView().environmentObject(appState),
                isActive: $navigateToLogin,
                label: { EmptyView() }
            )
            .hidden()
        )
    }
}
