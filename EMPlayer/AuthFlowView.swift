//
//  AuthFlowView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/16.
//

import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject var appState: AppState
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ServerSelectionView().environmentObject(appState)
                .navigationTitle("サーバ選択")
                .onChange(of: appState.server) { newValue in
                    print("server updated")
                    if appState.ready {
                        dismiss()
                    }
                }
                .onChange(of: appState.token) { newValue in
                    print("token updated")
                    if appState.ready {
                        dismiss()
                    }
                }
                .onChange(of: appState.userID) { newValue in
                    print("userID updated")
                    if appState.ready {
                        dismiss()
                    }
                }
        }
    }
}

