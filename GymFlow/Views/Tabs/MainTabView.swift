import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "list.bullet.rectangle.portrait.fill")
                }

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            RecoveryView()
                .tabItem {
                    Label("Recovery", systemImage: "heart.text.square.fill")
                }
        }
    }
}
