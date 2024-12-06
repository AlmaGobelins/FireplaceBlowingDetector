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
    
    
    //let spherosNames: [String] = ["SB-C7A8"]
    let spherosNames: [String] = ["SB-42C1"]
    //let spherosNames: [String] = ["SB-A729"]
    private let collisionDetector = CollisionDetector(toyBox: SharedToyBox.instance)
    
    var body: some View {
        VStack {
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
        .onAppear {
            connectedToServer = wsClient.connectTo(route:"phoneFireplace")
            microphoneMonitor.startMonitoring()
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
                wsClient.sendMessage("souffle", toRoute: "phoneFireplace")
            }
        }
    }
}

#Preview {
    ContentView()
}
