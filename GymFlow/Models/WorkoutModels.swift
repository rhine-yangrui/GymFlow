import Foundation

enum WorkoutDayKind: String, CaseIterable, Codable, Identifiable {
    case custom = "Custom"
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
    case fullBody = "Full Body"
    case upper = "Upper"
    case lower = "Lower"
    case chestFocus = "Chest Focus"
    case conditioning = "Conditioning"
    case recovery = "Recovery"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .custom:
            return "dumbbell.fill"
        case .push:
            return "arrow.up.right.circle.fill"
        case .pull:
            return "arrow.down.left.circle.fill"
        case .legs:
            return "figure.walk.motion"
        case .fullBody:
            return "figure.mixed.cardio"
        case .upper:
            return "figure.strengthtraining.functional"
        case .lower:
            return "figure.run"
        case .chestFocus:
            return "bolt.heart.fill"
        case .conditioning:
            return "timer"
        case .recovery:
            return "figure.cooldown"
        }
    }
}

enum EffortFeedback: String, CaseIterable, Codable, Identifiable {
    case tooEasy = "Too Easy"
    case tooHard = "Too Hard"

    var id: String { rawValue }
}

enum ExerciseLiveStatus: String, CaseIterable, Codable, Identifiable {
    case ready = "Ready"
    case training = "Training"
    case breakTime = "Break"
    case completed = "Complete"

    var id: String { rawValue }
}

struct ExerciseSwapOption: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var targetReps: String
    var suggestedWeight: String
    var hint: String

    init(
        id: UUID = UUID(),
        name: String,
        targetReps: String,
        suggestedWeight: String,
        hint: String
    ) {
        self.id = id
        self.name = name
        self.targetReps = targetReps
        self.suggestedWeight = suggestedWeight
        self.hint = hint
    }
}

struct Exercise: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var targetSets: Int
    var targetReps: String
    var suggestedWeight: String
    var hint: String
    var alternatives: [ExerciseSwapOption]

    init(
        id: UUID = UUID(),
        name: String,
        targetSets: Int,
        targetReps: String,
        suggestedWeight: String,
        hint: String,
        alternatives: [ExerciseSwapOption] = []
    ) {
        self.id = id
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.suggestedWeight = suggestedWeight
        self.hint = hint
        self.alternatives = alternatives
    }

    var targetRepCount: Int {
        let repValues = targetReps
            .split(separator: "-")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

        if repValues.count == 2 {
            return Int((Double(repValues[0]) + Double(repValues[1])) / 2.0)
        }

        return repValues.first ?? 10
    }
}

struct DailyWorkoutOverride: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var workoutDay: WorkoutDay

    init(id: UUID = UUID(), date: Date, workoutDay: WorkoutDay) {
        self.id = id
        self.date = date
        self.workoutDay = workoutDay
    }
}

struct ScheduledWorkoutDay: Identifiable, Equatable {
    var id: Date { date }
    var date: Date
    var workoutDay: WorkoutDay
    var isCustomized: Bool
}

struct WorkoutDay: Identifiable, Codable, Equatable {
    let id: UUID
    var weekday: Int
    var kind: WorkoutDayKind
    var title: String
    var focusArea: String
    var estimatedMinutes: Int
    var exercises: [Exercise]

    init(
        id: UUID = UUID(),
        weekday: Int,
        kind: WorkoutDayKind,
        title: String,
        focusArea: String,
        estimatedMinutes: Int,
        exercises: [Exercise]
    ) {
        self.id = id
        self.weekday = weekday
        self.kind = kind
        self.title = title
        self.focusArea = focusArea
        self.estimatedMinutes = estimatedMinutes
        self.exercises = exercises
    }

    var isRecovery: Bool {
        kind == .recovery
    }
}

struct WorkoutPlan: Codable, Equatable {
    var generatedAt: Date
    var summary: String
    var days: [WorkoutDay]

    func day(for date: Date, calendar: Calendar = .current) -> WorkoutDay? {
        let weekday = calendar.component(.weekday, from: date)
        return days.first(where: { $0.weekday == weekday })
    }
}

struct ActiveWorkoutExerciseState: Identifiable, Codable, Equatable {
    let id: UUID
    var exerciseName: String
    var targetSets: Int
    var targetReps: String
    var hint: String
    var completedSets: Int
    var currentWeight: String
    var lastFeedback: EffortFeedback?
    var adjustmentNote: String?
    var liveStatus: ExerciseLiveStatus = .ready
    var phaseStartedAt: Date? = nil
    var lastSetDuration: TimeInterval? = nil
    var lastBreakDuration: TimeInterval? = nil
    var breakTargetSeconds: Int = 90

    var targetRepCount: Int {
        let repValues = targetReps
            .split(separator: "-")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

        if repValues.count == 2 {
            return Int((Double(repValues[0]) + Double(repValues[1])) / 2.0)
        }

        return repValues.first ?? 10
    }

    var isComplete: Bool {
        completedSets >= targetSets
    }
}

struct LoggedSet: Identifiable, Codable, Equatable {
    let id: UUID
    var exerciseID: UUID
    var exerciseName: String
    var completedAt: Date
    var reps: Int
    var weight: String
    var setDuration: TimeInterval?
    var intervalSincePreviousSet: TimeInterval?
    var feedback: EffortFeedback?

    init(
        id: UUID = UUID(),
        exerciseID: UUID,
        exerciseName: String,
        completedAt: Date,
        reps: Int,
        weight: String,
        setDuration: TimeInterval? = nil,
        intervalSincePreviousSet: TimeInterval? = nil,
        feedback: EffortFeedback?
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.completedAt = completedAt
        self.reps = reps
        self.weight = weight
        self.setDuration = setDuration
        self.intervalSincePreviousSet = intervalSincePreviousSet
        self.feedback = feedback
    }
}

struct ActiveWorkout: Codable, Equatable {
    let id: UUID
    var dayID: UUID
    var dayTitle: String
    var date: Date
    var startedAt: Date
    var estimatedMinutes: Int
    var exerciseStates: [ActiveWorkoutExerciseState]
    var loggedSets: [LoggedSet]

    init(
        id: UUID = UUID(),
        dayID: UUID,
        dayTitle: String,
        date: Date,
        startedAt: Date,
        estimatedMinutes: Int,
        exerciseStates: [ActiveWorkoutExerciseState],
        loggedSets: [LoggedSet]
    ) {
        self.id = id
        self.dayID = dayID
        self.dayTitle = dayTitle
        self.date = date
        self.startedAt = startedAt
        self.estimatedMinutes = estimatedMinutes
        self.exerciseStates = exerciseStates
        self.loggedSets = loggedSets
    }

    var completedSetCount: Int {
        exerciseStates.reduce(0) { $0 + $1.completedSets }
    }

    var totalSetCount: Int {
        exerciseStates.reduce(0) { $0 + $1.targetSets }
    }

    var lastLoggedSet: LoggedSet? {
        loggedSets.max(by: { $0.completedAt < $1.completedAt })
    }
}

struct WorkoutSession: Identifiable, Codable, Equatable {
    let id: UUID
    var dayID: UUID
    var dayTitle: String
    var date: Date
    var startedAt: Date
    var completedAt: Date
    var estimatedMinutes: Int
    var loggedSets: [LoggedSet]

    init(
        id: UUID = UUID(),
        dayID: UUID,
        dayTitle: String,
        date: Date,
        startedAt: Date,
        completedAt: Date,
        estimatedMinutes: Int,
        loggedSets: [LoggedSet]
    ) {
        self.id = id
        self.dayID = dayID
        self.dayTitle = dayTitle
        self.date = date
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.estimatedMinutes = estimatedMinutes
        self.loggedSets = loggedSets
    }
}
