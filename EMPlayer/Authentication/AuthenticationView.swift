//
//  AuthenticationView.swift
//  EMPlayer
//
//  Created by sonson on 2025/03/03.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    let accountManager = AccountManager()
    
    @Binding var isPresented: Bool  // シートの表示状態を制御
    
    var body: some View {
        NavigationStack {
            ServerSelectionView().environmentObject(appState).environmentObject(accountManager)
                .navigationTitle("Select server")
                .onChange(of: appState.server) {
                    print("server updated")
                    if appState.ready {
                        isPresented = false
                    }
                }
                .onChange(of: appState.token) {
                    print("token updated")
                    if appState.ready {
                        isPresented = false
                    }
                }
                .onChange(of: appState.userID) {
                    print("userID updated")
                    if appState.ready {
                        isPresented = false
                    }
                }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

#Preview {
    @State var showAuthSheet = false
    let appState = AppState()
    AuthenticationView(isPresented: $showAuthSheet).environmentObject(appState)
}
