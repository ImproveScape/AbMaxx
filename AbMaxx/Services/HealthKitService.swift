import Foundation
import HealthKit

nonisolated enum HealthKitResult: Sendable {
    case success
    case unavailable
    case entitlementMissing
    case denied
    case error(String)
}

@MainActor
class HealthKitService {
    static let shared = HealthKitService()

    var isConnected: Bool {
        UserDefaults.standard.bool(forKey: "healthkit_connected")
    }

    var todaySteps: Double = 0
    var todayActiveCalories: Double = 0
    var onDataUpdate: (() -> Void)?

    private let healthStore = HKHealthStore()

    func connect() async -> HealthKitResult {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }

        let stepType = HKQuantityType(.stepCount)
        let activeEnergyType = HKQuantityType(.activeEnergyBurned)
        let typesToRead: Set<HKObjectType> = [stepType, activeEnergyType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            UserDefaults.standard.set(true, forKey: "healthkit_connected")
            await fetchTodayData()
            return .success
        } catch {
            let nsError = error as NSError
            if nsError.domain == "com.apple.healthkit" && nsError.code == 5 {
                return .entitlementMissing
            }
            return .error(error.localizedDescription)
        }
    }

    func disconnect() {
        UserDefaults.standard.set(false, forKey: "healthkit_connected")
        todaySteps = 0
        todayActiveCalories = 0
    }

    func fetchTodayData() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        todaySteps = await querySum(type: HKQuantityType(.stepCount), unit: .count(), predicate: predicate)
        todayActiveCalories = await querySum(type: HKQuantityType(.activeEnergyBurned), unit: .kilocalorie(), predicate: predicate)
        onDataUpdate?()
    }

    private func querySum(type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async -> Double {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
}
