//
//  Untitled.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/14.
//

import SwiftUI
import Foundation
import CocoaAsyncSocket

// サーバ情報のデータモデル
struct ServerInfo: Codable, Identifiable, Hashable {
    let address: String
    let id: String
    let name: String
    
    // JSON のキーと Swift のプロパティ名をマッピング
    enum CodingKeys: String, CodingKey {
        case address = "Address"
        case id = "Id"
        case name = "Name"
    }
}

class ServerDiscoveryModel: NSObject, ObservableObject, GCDAsyncUdpSocketDelegate {
    @Published var servers: [ServerInfo] = []
    var udpSocket: GCDAsyncUdpSocket!

    override init() {
        print(#function)
        super.init()
        setupSocket()
    }

    func setupSocket() {
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)

        do {
            try udpSocket.enableBroadcast(true) // ブロードキャストを許可
            try udpSocket.bind(toPort: 7359)    // ポートをバインド
            try udpSocket.beginReceiving()
            print("UDP socket set up")
        } catch {
            print("Socket error: \(error)")
        }
    }

    func sendBroadcastMessage() {
        self.servers.removeAll()
        
        let message = "who is EmbyServer?"
        let data = message.data(using: .utf8)!
        let broadcastAddress = "255.255.255.255" // 必要に応じてローカルサブネットブロードキャストに変更

        udpSocket.send(data, toHost: broadcastAddress, port: 7359, withTimeout: -1, tag: 0)
        print("Sent message: \(message)")
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {

        let decoder = JSONDecoder()
        
        if let message = String(data: data, encoding: .utf8) {
            print("OK - Received message: \(message)")
        }
        do {
            let serverInfo = try decoder.decode(ServerInfo.self, from: data)
            self.servers.append(serverInfo)
            print(serverInfo)
        } catch {
            print("デコードエラー: \(error)")
        }
    }
}
