import Foundation

@MainActor
struct ProgressViewModel {
    let store: AppStore
    private let calendar = Calendar.current
    private static let chartFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var hasCompletedWorkouts: Bool {
        store.completedSessions.isEmpty == false
    }

    var totalWorkouts: Int {
        store.completedSessions.count
    }

    var currentStreak: Int {
        let uniqueDates = uniqueWorkoutDates
        guard uniqueDates.isEmpty == false else { return 0 }

        var streak = 0
        var comparisonDate = calendar.startOfDay(for: .now)

        if calendar.isDate(uniqueDates[0], inSameDayAs: comparisonDate) == false,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: comparisonDate),
           calendar.isDate(uniqueDates[0], inSameDayAs: yesterday) {
            comparisonDate = yesterday
        }

        for date in uniqueDates {
            if calendar.isDate(date, inSameDayAs: comparisonDate) {
                streak += 1
                comparisonDate = calendar.date(byAdding: .day, value: -1, to: comparisonDate) ?? comparisonDate
            } else {
                break
            }
        }

        return streak
    }

    var weeklyGoal: Int {
        store.userProfile?.frequency.weeklySessions ?? 3
    }

    var weeklyCompletionCount: Int {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: .now)) ?? .now
        return store.completedSessions.filter { $0.completedAt >= start }.count
    }

    var weeklyCompletionProgress: Double {
        min(Double(weeklyCompletionCount) / Double(max(weeklyGoal, 1)), 1.0)
    }

    var personalRecords: [PersonalRecord] {
        let grouped = Dictionary(grouping: store.completedSessions.flatMap(\.loggedSets), by: \.exerciseName)

        return grouped.compactMap { exerciseName, sets in
            guard let bestSet = sets.max(by: { numericWeight(for: $0.weight) < numericWeight(for: $1.weight) }) else {
                return nil
            }

            return PersonalRecord(
                id: exerciseName,
                exerciseName: exerciseName,
                weight: bestSet.weight,
                reps: bestSet.reps,
                achievedOn: bestSet.completedAt
            )
        }
        .sorted { numericWeight(for: $0.weight) > numericWeight(for: $1.weight) }
        .prefix(3)
        .map { $0 }
    }

    var badges: [Badge] {
        [
            Badge(
                id: "first-workout",
                title: "First Workout",
                subtitle: "Completed your first session",
                icon: "sparkles",
                isUnlocked: totalWorkouts >= 1
            ),
            Badge(
                id: "streak-3",
                title: "3-Day Streak",
                subtitle: "Showed up three days in a row",
                icon: "flame.fill",
                isUnlocked: currentStreak >= 3
            ),
            Badge(
                id: "week-complete",
                title: "Weekly Goal",
                subtitle: "Hit this week’s planned sessions",
                icon: "checkmark.seal.fill",
                isUnlocked: weeklyCompletionCount >= weeklyGoal
            )
        ]
    }

    var recentWins: [String] {
        store.completedSessions.prefix(3).map {
            "\($0.dayTitle) finished with \($0.loggedSets.count) logged sets."
        }
    }

    var trendEntries: [TrendEntry] {
        let pressSessions = store.completedSessions
            .filter { session in
                session.loggedSets.contains { $0.exerciseName.localizedCaseInsensitiveContains("press") || $0.exerciseName.localizedCaseInsensitiveContains("push") }
            }
            .prefix(4)

        if pressSessions.isEmpty == false {
            return pressSessions.reversed().map { session in
                let maxWeight = session.loggedSets
                    .filter { $0.exerciseName.localizedCaseInsensitiveContains("press") || $0.exerciseName.localizedCaseInsensitiveContains("push") }
                    .map { numericWeight(for: $0.weight) }
                    .max() ?? Double(session.loggedSets.count)

                return TrendEntry(
                    label: Self.chartFormatter.string(from: session.completedAt),
                    value: maxWeight
                )
            }
        }

        return store.completedSessions.prefix(4).reversed().map {
            TrendEntry(
                label: Self.chartFormatter.string(from: $0.completedAt),
                value: Double($0.loggedSets.count)
            )
        }
    }

    private var uniqueWorkoutDates: [Date] {
        var uniqueDates: [Date] = []

        for session in store.completedSessions.sorted(by: { $0.completedAt > $1.completedAt }) {
            let startOfDay = calendar.startOfDay(for: session.completedAt)
            if uniqueDates.contains(where: { calendar.isDate($0, inSameDayAs: startOfDay) }) == false {
                uniqueDates.append(startOfDay)
            }
        }

        return uniqueDates
    }

    private func numericWeight(for weight: String) -> Double {
        let digits = weight.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
        guard let valueString = digits.first(where: { $0.isEmpty == false }),
              let value = Double(valueString) else {
            return 0
        }
        return value
    }
}
