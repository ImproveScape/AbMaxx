import Foundation

@MainActor
class DeviceIdentityService {
    static let shared = DeviceIdentityService()

    private let deviceIdKey = "abmaxx_device_id"

    var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }
}
