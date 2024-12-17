//
//  ContentView.swift
//  FireplaceBlowingDetector
//
//  Created by Mathieu Dubart on 25/11/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var microphoneMonitor = MicrophoneMonitor()
    @ObservedObject var wsClient = WebSocketClient.shared
    @State var connectedToServer: Bool = false
    @State var spheroIsConnected = false
    
    @State private var ip: String = "192.168.0.132:8080"
    @State private var route: String = "phoneFireplace"
    
    let spherosNames: [String] = ["SB-42C1"] // "SB-C7A8" - "SB-A729"
    
    private let collisionDetector = CollisionDetector(toyBox: SharedToyBox.instance)
    
    var body: some View {
        VStack {
            HStack {
                TextField("IP:", text: $ip)
                TextField("Route:", text: $route)
                
                Button("Connect") {
                    self.connectedToServer = wsClient.connectTo(route: route)
                    microphoneMonitor.startMonitoring()
                }
            }
            
            Text("Recording...")
                .font(.title)
                .foregroundStyle(.red)
            Image(systemName: "microphone")
                .foregroundStyle(.red)
            Spacer()
                .frame(height: 20)
            Text("Souffle détecté : \(microphoneMonitor.isSouffling)")
            Text("Connecté au server : \(connectedToServer)")
        }
        .padding()
        .onChange(of: ip) {
            wsClient.ipAdress = ip
        }
        .onAppear {
            SharedToyBox.instance.searchForBoltsNamed(spherosNames) { err in
                if err == nil {
                    print("Connected to sphero")
                    self.spheroIsConnected.toggle()
                    collisionDetector.startMonitoring()
                } else {
                    print(self.spheroIsConnected)
                }
            }
        }
        .onDisappear {
            SharedToyBox.instance.stopSensors()
            wsClient.disconnectFromAllRoutes()
            connectedToServer = false
        }
        .onChange(of: microphoneMonitor.isSouffling) {
            if self.connectedToServer && microphoneMonitor.isSouffling {
                wsClient.sendMessage("souffle", toRoute: route)
            }
        }
    }
}

#Preview {
    ContentView()
}
