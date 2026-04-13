import Foundation

@MainActor
class HealthKitService {
    static let shared = HealthKitService()

    var isConnected: Bool { false }
    var todaySteps: Double = 0
    var todayActiveCalories: Double = 0
    var onDataUpdate: (() -> Void)?

    func disconnect() {
        UserDefaults.standard.removeObject(forKey: "healthkit_connected")
        todaySteps = 0
        todayActiveCalories = 0
    }
}
