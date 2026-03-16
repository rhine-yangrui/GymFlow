import SwiftUI

@main
struct GymFlowApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(AppTheme.accent)
        }
    }
}
