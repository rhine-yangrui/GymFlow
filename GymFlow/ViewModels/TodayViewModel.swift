import Foundation

@MainActor
struct TodayViewModel {
    let store: AppStore
    private let calendar = Calendar.current

    var greeting: String {
        let hour = calendar.component(.hour, from: .now)

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    var activeWorkout: ActiveWorkout? {
        store.activeWorkoutForToday()
    }

    var completedSession: WorkoutSession? {
        store.completedSession()
    }

    var todayPlan: WorkoutDay? {
        store.todayPlan()
    }

    var progress: Double {
        guard let activeWorkout, activeWorkout.totalSetCount > 0 else { return 0 }
        return Double(activeWorkout.completedSetCount) / Double(activeWorkout.totalSetCount)
    }

    var encouragement: String {
        guard let activeWorkout else {
            return "Your plan is ready when you are."
        }

        if progress >= 1 {
            return "Everything is logged. Finish when you feel ready."
        }

        if progress >= 0.5 {
            return "You’re halfway through today’s session."
        }

        if activeWorkout.completedSetCount > 0 {
            return "Nice start. Keep the next few sets smooth."
        }

        return "Start with the first movement and let the rest of the workout unfold."
    }

    var todaySubtitle: String {
        guard let todayPlan else {
            return "Build your plan once and keep the next step obvious."
        }

        if todayPlan.isRecovery {
            return "Today is lighter on purpose. Recovery still counts."
        }

        return "\(todayPlan.focusArea) in about \(todayPlan.estimatedMinutes) min."
    }

    func state(for exercise: Exercise) -> ActiveWorkoutExerciseState? {
        activeWorkout?.exerciseStates.first(where: { $0.id == exercise.id })
    }
}
