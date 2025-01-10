//
//  WebsocketClient.swift
//  WebSocketClient
//
//  Created by digital on 22/10/2024.
//
// IP Fixe : 192.168.1.99

import SwiftUI
import NWWebSocket
import Network

class WebSocketClient: ObservableObject {
    struct Message: Identifiable, Equatable {
        let id = UUID().uuidString
        let content:String
    }
    
    static let shared:WebSocketClient = WebSocketClient()

    
    var routes = [String:NWWebSocket]()
    var reconnectTimer: Timer?

    var ipAdress: String = "192.168.0.166:8080"
    private let reconnectInterval: TimeInterval = 5.0
    
    @Published var isConnected: Bool = false
    
    
    func connectTo(route:String) -> Bool {
        stopReconnectTimer()

        let socketURL = URL(string: "ws://\(ipAdress)/\(route)")
        if let url = socketURL {
            let socket = NWWebSocket(url: url, connectAutomatically: true)
            
            socket.delegate = self
            socket.connect()
            routes[route] = socket
            print("Connected to WSServer @ \(url) -- Routes: \(routes)")
            return true
        }
        
        return false
    }
    
    private func startReconnectTimer(forRoute route: String) {
        stopReconnectTimer()
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if !self.isConnected {
                print("Attempting to reconnect...")
                _ = self.connectTo(route: route)
            } else {
                self.stopReconnectTimer()
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    func sendMessage(_ string: String, toRoute route:String) -> Void {
        self.routes[route]?.send(string: string)
    }
    
    func disconnect(route: String) -> Void {
        routes[route]?.disconnect()
        stopReconnectTimer()
    }
    
    func disconnectFromAllRoutes() -> Void {
        for route in routes {
            route.value.disconnect()
        }
        stopReconnectTimer()
        print("Disconnected from all routes.")
    }
}

extension WebSocketClient: WebSocketConnectionDelegate {
    
    func webSocketDidConnect(connection: WebSocketConnection) {
        // Respond to a WebSocket connection event
        print("WebSocket connected")
    }
    
    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        // Respond to a WebSocket disconnection event
        print("WebSocket disconnected")
    }
    
    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        // Respond to a WebSocket connection viability change event
        print("WebSocket viability: \(isViable)")
    }
    
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        // Respond to when a WebSocket connection migrates to a better network path
        // (e.g. A device moves from a cellular connection to a Wi-Fi connection)
    }
    
    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        // Respond to a WebSocket error event
        print("WebSocket error: \(error)")
        DispatchQueue.main.async {
            self.isConnected = false
            // Start reconnection attempts for the disconnected route
            if let route = self.routes.first(where: { $0.value === connection as? NWWebSocket })?.key {
                self.startReconnectTimer(forRoute: route)
            }
        }
    }
    
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        // Respond to a WebSocket connection receiving a Pong from the peer
        print("WebSocket received Pong")
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        // Respond to a WebSocket connection receiving a `String` message
        print("WebSocket received message: \(string)")
        
        if string == "ping" {
            self.sendMessage("pong", toRoute: "phoneFire")
        }
        
    
        
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        // Respond to a WebSocket connection receiving a binary `Data` message
        print("WebSocket received Data message \(data)")
    }
}
