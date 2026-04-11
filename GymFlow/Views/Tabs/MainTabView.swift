import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MainTabView: View {
    init() {
        #if canImport(UIKit)
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        let accentColor = UIColor(AppTheme.accent)
        let itemAppearance = appearance.stackedLayoutAppearance
        itemAppearance.selected.iconColor = accentColor
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ]
        itemAppearance.normal.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            RunView()
                .tabItem {
                    Label("Run", systemImage: "figure.run")
                }

            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "list.bullet.clipboard.fill")
                }

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            RecoveryView()
                .tabItem {
                    Label("Recovery", systemImage: "heart.circle.fill")
                }
        }
        .tint(AppTheme.accent)
        .imageScale(.large)
        .font(.system(size: 22))
    }
}
