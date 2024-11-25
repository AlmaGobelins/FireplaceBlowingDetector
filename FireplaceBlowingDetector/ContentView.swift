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
            connectedToServer = wsClient.connectTo(route:"fireplace")
            microphoneMonitor.startMonitoring()
        }
        .onDisappear {
            wsClient.disconnectFromAllRoutes()
            connectedToServer = false
        }
        .onChange(of: microphoneMonitor.isSouffling) {
            if self.connectedToServer && microphoneMonitor.isSouffling {
                wsClient.sendMessage("souffle", toRoute: "fireplace")
            }
        }
    }
}

#Preview {
    ContentView()
}
