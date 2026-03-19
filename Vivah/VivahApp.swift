import SwiftUI

@main
struct VivahApp: App {
    @StateObject private var store = WeddingStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: WeddingStore

    var body: some View {
        if store.isOnboardingComplete {
            ContentView()
                .environmentObject(store)
        } else {
            OnboardingView()
                .environmentObject(store)
        }
    }
}
