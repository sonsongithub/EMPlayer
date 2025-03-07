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
        ServerSelectionView().environmentObject(appState)
            .navigationTitle("サーバ選択")
            .onChange(of: appState.server) {
                print("server updated")
                if appState.ready {
                    dismiss()
                }
            }
            .onChange(of: appState.token) {
                print("token updated")
                if appState.ready {
                    dismiss()
                }
            }
            .onChange(of: appState.userID) {
                print("userID updated")
                if appState.ready {
                    dismiss()
                }
            }
    }
}

