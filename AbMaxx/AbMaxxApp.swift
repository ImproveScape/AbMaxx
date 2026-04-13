import SwiftUI
import RevenueCat

@main
struct AbMaxxApp: App {
    init() {
        Purchases.logLevel = .debug
        let apiKey = Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY.isEmpty
            ? Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
            : Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY
        Purchases.configure(withAPIKey: apiKey)
        SamplePhotoLoader.loadIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

}
