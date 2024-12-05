import SwiftUI

class CollisionDetector {
    private var isCollisionDetected = false
    private let gyroThreshold: Int = 200 // Augmentation du seuil pour une détection plus sensible
    private weak var toyBox: SharedToyBox?
    @ObservedObject var wsClient = WebSocketClient.shared

    
    var onCollisionDetected: (() -> Void)?
    
    init(toyBox: SharedToyBox) {
        self.toyBox = toyBox
    }
    
    func startMonitoring() {
        isCollisionDetected = false
        toyBox?.onGyroData = { [weak self] gyroData in
            self?.processGyroData(gyroData)
        }
    }
    
    func stopMonitoring() {
        toyBox?.onGyroData = nil
    }
    
    private func processGyroData(_ gyroData: ThreeAxisSensorData<Int>) {
        guard let x = gyroData.x,
              let y = gyroData.y,
              let z = gyroData.z else { return }
        
        // Calcul de l'intensité de la collision
        let collisionIntensity = sqrt(Double(x*x + y*y + z*z))
        
        if collisionIntensity > Double(gyroThreshold) && !isCollisionDetected {
            isCollisionDetected = true
            print("COLLISION DÉTECTÉE! Intensité: \(collisionIntensity)")
            print("Données gyroscopiques - X: \(x), Y: \(y), Z: \(z)")
            wsClient.sendMessage("allumer", toRoute: "phoneFireplace")
            onCollisionDetected?()
            
            // Réinitialisation après un délai pour éviter plusieurs détections consécutives
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isCollisionDetected = false
            }
        }
    }
}
