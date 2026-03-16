import Foundation

@MainActor
struct RecoveryViewModel {
    let store: AppStore

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
}
