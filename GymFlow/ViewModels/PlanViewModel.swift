import Foundation

@MainActor
struct PlanViewModel {
    let store: AppStore
    private let calendar = Calendar.current

    var orderedDays: [WorkoutDay] {
        guard let days = store.workoutPlan?.days else { return [] }

        let mondayFirstOrder = [2, 3, 4, 5, 6, 7, 1]
        return days.sorted {
            (mondayFirstOrder.firstIndex(of: $0.weekday) ?? 0) < (mondayFirstOrder.firstIndex(of: $1.weekday) ?? 0)
        }
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

    func isToday(_ day: WorkoutDay) -> Bool {
        day.weekday == calendar.component(.weekday, from: .now)
    }

    func weekdayLabel(for day: WorkoutDay) -> String {
        let symbols = calendar.weekdaySymbols
        let symbol = symbols.indices.contains(day.weekday - 1) ? symbols[day.weekday - 1] : "Day"
        return symbol
    }
}
