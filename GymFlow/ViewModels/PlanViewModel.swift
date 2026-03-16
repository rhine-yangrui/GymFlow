import Foundation

@MainActor
struct PlanViewModel {
    let store: AppStore
    private let calendar = Calendar.current
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var scheduledDays: [ScheduledWorkoutDay] {
        store.weeklySchedule()
    }

    var summary: String {
        store.workoutPlan?.summary ?? "Generate a plan to see your week."
    }

    var selectedFrequency: TrainingFrequency {
        store.userProfile?.frequency ?? .threeDays
    }

    var selectedLocation: WorkoutLocation {
        store.userProfile?.location ?? .gym
    }

    func isToday(_ day: ScheduledWorkoutDay) -> Bool {
        calendar.isDateInToday(day.date)
    }

    func weekdayLabel(for day: ScheduledWorkoutDay) -> String {
        let symbols = calendar.weekdaySymbols
        let weekday = calendar.component(.weekday, from: day.date)
        let symbol = symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : "Day"
        return symbol
    }

    func dateLabel(for day: ScheduledWorkoutDay) -> String {
        Self.shortDateFormatter.string(from: day.date)
    }
}
