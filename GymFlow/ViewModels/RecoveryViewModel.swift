import Foundation
import SwiftUI

@MainActor
struct RecoveryViewModel {
    let store: AppStore
    private let calendar = Calendar.current

    var latestCheckIn: RecoveryCheckIn? {
        store.latestRecoveryCheckIn()
    }

    var recommendation: RecoveryRecommendation? {
        latestCheckIn?.recommendation
    }

    var tips: [String] {
        [
            "Drink water before class and again before your workout block.",
            "If soreness is high, trim load first before skipping movement entirely.",
            "Aim for a consistent sleep window more than a perfect one.",
            "Keep recovery days easy enough that tomorrow still feels available."
        ]
    }

    var daysSinceLastWorkout: Int? {
        guard let lastDate = store.completedSessions
            .map(\.completedAt)
            .max() else { return nil }

        let today = calendar.startOfDay(for: .now)
        let then = calendar.startOfDay(for: lastDate)
        return calendar.dateComponents([.day], from: then, to: today).day
    }

    var recoveryScore: Int {
        guard let days = daysSinceLastWorkout else { return 100 }
        return min(max(days * 20, 20), 100)
    }

    var recoveryStatusLabel: String {
        switch recoveryScore {
        case 80...:
            return "Fully Recovered"
        case 50...:
            return "Moderate — Light workout recommended"
        default:
            return "Rest Day Recommended"
        }
    }

    var recoveryStatusColor: Color {
        switch recoveryScore {
        case 80...:
            return AppTheme.success
        case 50...:
            return AppTheme.warning
        default:
            return AppTheme.accentWarm
        }
    }

    var lastWorkoutLabel: String {
        guard let days = daysSinceLastWorkout else {
            return "No workouts logged yet"
        }

        switch days {
        case 0:
            return "Last Workout: Today"
        case 1:
            return "Last Workout: 1 day ago"
        default:
            return "Last Workout: \(days) days ago"
        }
    }
}
