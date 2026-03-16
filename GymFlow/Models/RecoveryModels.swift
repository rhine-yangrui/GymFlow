import Foundation

enum RecoveryRating: Int, CaseIterable, Codable, Identifiable {
    case low = 1
    case medium = 2
    case high = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Okay"
        case .high:
            return "High"
        }
    }
}

enum RecoveryRecommendation: String, CaseIterable, Codable, Identifiable {
    case trainAsPlanned = "Train as planned"
    case goLighterToday = "Go lighter today"
    case takeRecoveryDay = "Take a recovery day"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .trainAsPlanned:
            return "checkmark.circle.fill"
        case .goLighterToday:
            return "dial.low.fill"
        case .takeRecoveryDay:
            return "bed.double.fill"
        }
    }

    var message: String {
        switch self {
        case .trainAsPlanned:
            return "Your check-in looks solid. Stay smooth, keep form clean, and train normally."
        case .goLighterToday:
            return "A lighter day can protect momentum. Keep the habit, trim the intensity."
        case .takeRecoveryDay:
            return "Rest is part of progress. Give yourself space to recover and come back sharper."
        }
    }

    static func makeRecommendation(
        energy: RecoveryRating,
        soreness: RecoveryRating,
        sleep: RecoveryRating
    ) -> RecoveryRecommendation {
        if energy == .low && sleep == .low {
            return .takeRecoveryDay
        }

        if soreness == .high && sleep != .high {
            return .goLighterToday
        }

        let readinessScore = energy.rawValue + sleep.rawValue - soreness.rawValue

        if readinessScore <= 1 {
            return .takeRecoveryDay
        }

        if readinessScore == 2 || soreness == .high {
            return .goLighterToday
        }

        return .trainAsPlanned
    }
}

struct RecoveryCheckIn: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var energyLevel: RecoveryRating
    var soreness: RecoveryRating
    var sleepQuality: RecoveryRating
    var recommendation: RecoveryRecommendation

    init(
        id: UUID = UUID(),
        date: Date,
        energyLevel: RecoveryRating,
        soreness: RecoveryRating,
        sleepQuality: RecoveryRating,
        recommendation: RecoveryRecommendation
    ) {
        self.id = id
        self.date = date
        self.energyLevel = energyLevel
        self.soreness = soreness
        self.sleepQuality = sleepQuality
        self.recommendation = recommendation
    }
}
