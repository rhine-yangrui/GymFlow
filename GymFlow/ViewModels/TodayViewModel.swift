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

    var completedSessionsToday: [WorkoutSession] {
        store.completedSessions(on: .now)
    }

    var todayPlan: WorkoutDay? {
        store.workoutDay(for: .now)
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

        let sessionSummary = completedSessionsToday.isEmpty
            ? ""
            : " \(completedSessionsToday.count) session\(completedSessionsToday.count == 1 ? "" : "s") logged today."

        if todayPlan.isRecovery && todayPlan.exercises.isEmpty {
            return "The day is open. Recover, or build a session when you want.\(sessionSummary)"
        }

        return "\(todayPlan.focusArea) in about \(todayPlan.estimatedMinutes) min.\(sessionSummary)"
    }

    func state(for exercise: Exercise) -> ActiveWorkoutExerciseState? {
        activeWorkout?.exerciseStates.first(where: { $0.id == exercise.id })
    }

    func formattedInterval(_ interval: TimeInterval?) -> String {
        guard let interval else { return "No sets logged yet" }
        let totalSeconds = max(Int(interval.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }
}
