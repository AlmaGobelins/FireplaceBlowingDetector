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

    @State var spheroIsConnected = false
    let spherosNames: [String] = ["SB-2020"] // "SB-C7A8" - "SB-A729"
    
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
        }
        .padding()
        .onAppear {
            let _ = wsClient.connectTo(route: "phoneFire")

            SharedToyBox.instance.searchForBoltsNamed(spherosNames) { err in
                if err == nil {
                    print("Connected to sphero")
                    self.spheroIsConnected.toggle()
                    collisionDetector.startMonitoring()
                } else {
                    print(self.spheroIsConnected)
                }
            }
            
            microphoneMonitor.startMonitoring()
        }
        .onDisappear {
            SharedToyBox.instance.stopSensors()
            wsClient.disconnectFromAllRoutes()
        }
        .onChange(of: microphoneMonitor.isSouffling) {
                wsClient.sendMessage("souffle", toRoute: "phoneFire")
        }
    }
}

#Preview {
    ContentView()
}
