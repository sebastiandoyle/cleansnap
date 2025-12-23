import SwiftUI

@main
struct CleanSnapApp: App {
    @StateObject private var storeManager = StoreManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environmentObject(storeManager)
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .environmentObject(storeManager)
            }
        }
    }
}
