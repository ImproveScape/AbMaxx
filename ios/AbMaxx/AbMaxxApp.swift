import SwiftUI
import RevenueCat

@main
struct AbMaxxApp: App {
    init() {
        #if DEBUG
        Purchases.logLevel = .debug
        let apiKey = Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY.isEmpty
            ? Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
            : Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY
        #else
        Purchases.logLevel = .warn
        let apiKey = Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
        #endif
        if !apiKey.isEmpty {
            Purchases.configure(withAPIKey: apiKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

}
