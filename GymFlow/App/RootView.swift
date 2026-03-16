import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            AppTheme.shell
                .ignoresSafeArea()

            if store.hasCompletedOnboarding {
                MainTabView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            } else {
                OnboardingFlowView()
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.98)), removal: .opacity))
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.88), value: store.hasCompletedOnboarding)
    }
}

#Preview {
    RootView()
        .environmentObject(AppStore.preview)
}
