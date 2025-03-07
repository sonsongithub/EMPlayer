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
                .navigationTitle("サーバ選択")
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
        }
    }
}

#Preview {
//    AuthenticationView()
}
