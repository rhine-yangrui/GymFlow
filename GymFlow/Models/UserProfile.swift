import Foundation

enum FitnessGoal: String, CaseIterable, Codable, Identifiable {
    case buildMuscle = "Build muscle"
    case loseFat = "Lose fat"
    case stayConsistent = "Stay consistent"
    case chestFocus = "Chest focus"
    case generalFitness = "General fitness"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .buildMuscle:
            return "figure.strengthtraining.traditional"
        case .loseFat:
            return "flame.fill"
        case .stayConsistent:
            return "calendar.badge.clock"
        case .chestFocus:
            return "figure.arms.open"
        case .generalFitness:
            return "heart.text.square.fill"
        }
    }

    var summary: String {
        switch self {
        case .buildMuscle:
            return "Lift with a little more volume and steady progression."
        case .loseFat:
            return "Keep sessions efficient with simple strength and conditioning."
        case .stayConsistent:
            return "Lower the setup cost so workouts are easier to repeat."
        case .chestFocus:
            return "Bias the week toward pressing and chest accessories."
        case .generalFitness:
            return "Balance full-body strength, energy, and recovery."
        }
    }
}

enum TrainingFrequency: String, CaseIterable, Codable, Identifiable {
    case twoDays = "2 days"
    case threeDays = "3 days"
    case fourDays = "4 days"
    case fivePlusDays = "5+ days"

    var id: String { rawValue }

    var weeklySessions: Int {
        switch self {
        case .twoDays:
            return 2
        case .threeDays:
            return 3
        case .fourDays:
            return 4
        case .fivePlusDays:
            return 5
        }
    }

    var summary: String {
        switch self {
        case .twoDays:
            return "Compact schedule with recovery room between workouts."
        case .threeDays:
            return "Balanced week that keeps planning light."
        case .fourDays:
            return "More structure with two heavier and two lighter sessions."
        case .fivePlusDays:
            return "Frequent training with built-in lighter sessions."
        }
    }
}

enum WorkoutLocation: String, CaseIterable, Codable, Identifiable {
    case gym = "Gym"
    case home = "Dorm / home"
    case both = "Both"

    var id: String { rawValue }

    var summary: String {
        switch self {
        case .gym:
            return "Use machines and dumbbells for quick, reliable setup."
        case .home:
            return "Rely on bodyweight, bands, and backpack-friendly moves."
        case .both:
            return "Keep swap-friendly options for busy class days."
        }
    }
}

enum ExperienceLevel: String, CaseIterable, Codable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case returning = "Returning after a break"

    var id: String { rawValue }

    var summary: String {
        switch self {
        case .beginner:
            return "Simple exercise choices, clear cues, and lighter volume."
        case .intermediate:
            return "Moderate challenge with room to push hard when you feel good."
        case .returning:
            return "A little gentler at first so consistency comes back faster."
        }
    }
}

struct UserProfile: Codable, Equatable {
    var goal: FitnessGoal
    var frequency: TrainingFrequency
    var location: WorkoutLocation
    var experienceLevel: ExperienceLevel
    var createdAt: Date = .now
}
