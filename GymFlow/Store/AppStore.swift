import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var userProfile: UserProfile? = nil {
        didSet { save(userProfile, for: .userProfile) }
    }
    @Published private(set) var workoutPlan: WorkoutPlan? = nil {
        didSet { save(workoutPlan, for: .workoutPlan) }
    }
    @Published private(set) var activeWorkout: ActiveWorkout? = nil {
        didSet { save(activeWorkout, for: .activeWorkout) }
    }
    @Published private(set) var completedSessions: [WorkoutSession] = [] {
        didSet { save(completedSessions, for: .completedSessions) }
    }
    @Published private(set) var recoveryHistory: [RecoveryCheckIn] = [] {
        didSet { save(recoveryHistory, for: .recoveryHistory) }
    }

    private let defaults: UserDefaults
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    private let calendar = Calendar.current

    enum StorageKey: String {
        case userProfile = "gymflow.userProfile"
        case workoutPlan = "gymflow.workoutPlan"
        case activeWorkout = "gymflow.activeWorkout"
        case completedSessions = "gymflow.completedSessions"
        case recoveryHistory = "gymflow.recoveryHistory"
    }

    init(defaults: UserDefaults = .standard, preview: Bool = false) {
        self.defaults = defaults

        if preview {
            let sample = AppStore.makePreviewState()
            userProfile = sample.userProfile
            workoutPlan = sample.workoutPlan
            activeWorkout = sample.activeWorkout
            completedSessions = sample.completedSessions
            recoveryHistory = sample.recoveryHistory
        } else {
            userProfile = load(UserProfile.self, for: .userProfile)
            workoutPlan = load(WorkoutPlan.self, for: .workoutPlan)
            activeWorkout = load(ActiveWorkout.self, for: .activeWorkout)
            completedSessions = load([WorkoutSession].self, for: .completedSessions) ?? []
            recoveryHistory = load([RecoveryCheckIn].self, for: .recoveryHistory) ?? []
            clearStaleActiveWorkoutIfNeeded()
        }
    }

    var hasCompletedOnboarding: Bool {
        userProfile != nil && workoutPlan != nil
    }

    func completeOnboarding(with profile: UserProfile) {
        userProfile = profile
        workoutPlan = WorkoutPlanGenerator.makePlan(for: profile)
        activeWorkout = nil
        if completedSessions.isEmpty == false || recoveryHistory.isEmpty == false {
            completedSessions = []
            recoveryHistory = []
        }
    }

    func updatePlan(frequency: TrainingFrequency, location: WorkoutLocation) {
        guard var userProfile else { return }
        userProfile.frequency = frequency
        userProfile.location = location
        self.userProfile = userProfile
        workoutPlan = WorkoutPlanGenerator.makePlan(for: userProfile)
    }

    func todayPlan(referenceDate: Date = .now) -> WorkoutDay? {
        workoutPlan?.day(for: referenceDate, calendar: calendar)
    }

    func activeWorkoutForToday(referenceDate: Date = .now) -> ActiveWorkout? {
        guard let activeWorkout else { return nil }
        return calendar.isDate(activeWorkout.date, inSameDayAs: referenceDate) ? activeWorkout : nil
    }

    func completedSession(on date: Date = .now) -> WorkoutSession? {
        completedSessions.first(where: { calendar.isDate($0.completedAt, inSameDayAs: date) })
    }

    func startWorkout(on date: Date = .now) {
        guard activeWorkoutForToday(referenceDate: date) == nil else { return }
        guard completedSession(on: date) == nil else { return }
        guard let workoutDay = todayPlan(referenceDate: date), workoutDay.isRecovery == false else { return }

        activeWorkout = ActiveWorkout(
            dayID: workoutDay.id,
            dayTitle: workoutDay.title,
            date: calendar.startOfDay(for: date),
            startedAt: date,
            estimatedMinutes: workoutDay.estimatedMinutes,
            exerciseStates: workoutDay.exercises.map {
                ActiveWorkoutExerciseState(
                    id: $0.id,
                    exerciseName: $0.name,
                    targetSets: $0.targetSets,
                    targetReps: $0.targetReps,
                    hint: $0.hint,
                    completedSets: 0,
                    currentWeight: $0.suggestedWeight,
                    lastFeedback: nil,
                    adjustmentNote: nil
                )
            },
            loggedSets: []
        )
    }

    func logSet(for exerciseID: UUID, at date: Date = .now) {
        guard var activeWorkout = activeWorkoutForToday(referenceDate: date) else { return }
        guard let index = activeWorkout.exerciseStates.firstIndex(where: { $0.id == exerciseID }) else { return }
        guard activeWorkout.exerciseStates[index].completedSets < activeWorkout.exerciseStates[index].targetSets else { return }

        activeWorkout.exerciseStates[index].completedSets += 1
        activeWorkout.exerciseStates[index].adjustmentNote = "Set logged. Stay smooth on the next one."

        let exerciseState = activeWorkout.exerciseStates[index]
        activeWorkout.loggedSets.append(
            LoggedSet(
                exerciseID: exerciseState.id,
                exerciseName: exerciseState.exerciseName,
                completedAt: date,
                reps: exerciseState.targetRepCount,
                weight: exerciseState.currentWeight,
                feedback: exerciseState.lastFeedback
            )
        )

        self.activeWorkout = activeWorkout
    }

    func updateDifficulty(for exerciseID: UUID, feedback: EffortFeedback) {
        guard var activeWorkout = activeWorkoutForToday() else { return }
        guard let index = activeWorkout.exerciseStates.firstIndex(where: { $0.id == exerciseID }) else { return }

        let currentWeight = activeWorkout.exerciseStates[index].currentWeight
        activeWorkout.exerciseStates[index].currentWeight = adjustedWeight(from: currentWeight, feedback: feedback)
        activeWorkout.exerciseStates[index].lastFeedback = feedback
        activeWorkout.exerciseStates[index].adjustmentNote = feedback == .tooEasy
            ? "Try a slightly stronger next set if your form still feels clean."
            : "Scale this down a touch and keep the reps crisp."

        self.activeWorkout = activeWorkout
    }

    func finishWorkout(at date: Date = .now) {
        guard let activeWorkout = activeWorkoutForToday(referenceDate: date) else { return }

        let session = WorkoutSession(
            dayID: activeWorkout.dayID,
            dayTitle: activeWorkout.dayTitle,
            date: activeWorkout.date,
            startedAt: activeWorkout.startedAt,
            completedAt: date,
            estimatedMinutes: activeWorkout.estimatedMinutes,
            loggedSets: activeWorkout.loggedSets
        )

        completedSessions.removeAll { calendar.isDate($0.completedAt, inSameDayAs: date) }
        completedSessions.insert(session, at: 0)
        completedSessions.sort { $0.completedAt > $1.completedAt }
        self.activeWorkout = nil
    }

    func swapExercise(dayID: UUID, exerciseID: UUID, with option: ExerciseSwapOption) {
        guard var workoutPlan else { return }
        guard let dayIndex = workoutPlan.days.firstIndex(where: { $0.id == dayID }) else { return }
        guard let exerciseIndex = workoutPlan.days[dayIndex].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }

        workoutPlan.days[dayIndex].exercises[exerciseIndex].name = option.name
        workoutPlan.days[dayIndex].exercises[exerciseIndex].targetReps = option.targetReps
        workoutPlan.days[dayIndex].exercises[exerciseIndex].suggestedWeight = option.suggestedWeight
        workoutPlan.days[dayIndex].exercises[exerciseIndex].hint = option.hint
        self.workoutPlan = workoutPlan

        if var activeWorkout, activeWorkout.dayID == dayID,
           let activeIndex = activeWorkout.exerciseStates.firstIndex(where: { $0.id == exerciseID }) {
            activeWorkout.exerciseStates[activeIndex].exerciseName = option.name
            activeWorkout.exerciseStates[activeIndex].targetReps = option.targetReps
            activeWorkout.exerciseStates[activeIndex].currentWeight = option.suggestedWeight
            activeWorkout.exerciseStates[activeIndex].hint = option.hint
            self.activeWorkout = activeWorkout
        }
    }

    func saveRecoveryCheckIn(
        energy: RecoveryRating,
        soreness: RecoveryRating,
        sleep: RecoveryRating,
        date: Date = .now
    ) {
        let recommendation = RecoveryRecommendation.makeRecommendation(
            energy: energy,
            soreness: soreness,
            sleep: sleep
        )

        let checkIn = RecoveryCheckIn(
            date: calendar.startOfDay(for: date),
            energyLevel: energy,
            soreness: soreness,
            sleepQuality: sleep,
            recommendation: recommendation
        )

        recoveryHistory.removeAll { calendar.isDate($0.date, inSameDayAs: date) }
        recoveryHistory.insert(checkIn, at: 0)
        recoveryHistory.sort { $0.date > $1.date }
    }

    func latestRecoveryCheckIn(on date: Date = .now) -> RecoveryCheckIn? {
        recoveryHistory.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
    }

    private func adjustedWeight(from current: String, feedback: EffortFeedback) -> String {
        if current.localizedCaseInsensitiveContains("bodyweight") {
            return feedback == .tooEasy ? "Bodyweight + 10 lb" : "Assisted bodyweight"
        }

        let digits = current.components(separatedBy: CharacterSet.decimalDigits.inverted)
        guard let valueString = digits.first(where: { $0.isEmpty == false }),
              let value = Int(valueString) else {
            return current
        }

        let updatedValue = max(5, value + (feedback == .tooEasy ? 5 : -5))

        if let range = current.range(of: valueString) {
            return current.replacingCharacters(in: range, with: "\(updatedValue)")
        }

        return current
    }

    private func clearStaleActiveWorkoutIfNeeded() {
        guard let activeWorkout else { return }
        if calendar.isDateInToday(activeWorkout.date) == false {
            self.activeWorkout = nil
        }
    }

    private func load<Value: Decodable>(_ type: Value.Type, for key: StorageKey) -> Value? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func save<Value: Encodable>(_ value: Value?, for key: StorageKey) {
        guard let value else {
            defaults.removeObject(forKey: key.rawValue)
            return
        }

        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
    }
}

extension AppStore {
    static let preview = AppStore(preview: true)

    private static func makePreviewState() -> (
        userProfile: UserProfile,
        workoutPlan: WorkoutPlan,
        activeWorkout: ActiveWorkout?,
        completedSessions: [WorkoutSession],
        recoveryHistory: [RecoveryCheckIn]
    ) {
        let profile = UserProfile(
            goal: .buildMuscle,
            frequency: .fourDays,
            location: .both,
            experienceLevel: .beginner
        )
        let plan = WorkoutPlanGenerator.makePlan(for: profile)
        let today = plan.day(for: .now) ?? plan.days.first!

        let activeWorkout = ActiveWorkout(
            dayID: today.id,
            dayTitle: today.title,
            date: Calendar.current.startOfDay(for: .now),
            startedAt: .now.addingTimeInterval(-900),
            estimatedMinutes: today.estimatedMinutes,
            exerciseStates: today.exercises.enumerated().map { index, exercise in
                ActiveWorkoutExerciseState(
                    id: exercise.id,
                    exerciseName: exercise.name,
                    targetSets: exercise.targetSets,
                    targetReps: exercise.targetReps,
                    hint: exercise.hint,
                    completedSets: min(index, 2),
                    currentWeight: exercise.suggestedWeight,
                    lastFeedback: index == 0 ? .tooEasy : nil,
                    adjustmentNote: index == 0 ? "Try a slightly stronger next set if your form still feels clean." : nil
                )
            },
            loggedSets: []
        )

        let completedSession = WorkoutSession(
            dayID: today.id,
            dayTitle: today.title,
            date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now,
            startedAt: Calendar.current.date(byAdding: .minute, value: -48, to: .now) ?? .now,
            completedAt: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now,
            estimatedMinutes: today.estimatedMinutes,
            loggedSets: today.exercises.map {
                LoggedSet(
                    exerciseID: $0.id,
                    exerciseName: $0.name,
                    completedAt: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now,
                    reps: $0.targetRepCount,
                    weight: $0.suggestedWeight,
                    feedback: nil
                )
            }
        )

        let recovery = RecoveryCheckIn(
            date: .now,
            energyLevel: .medium,
            soreness: .medium,
            sleepQuality: .high,
            recommendation: .goLighterToday
        )

        return (
            userProfile: profile,
            workoutPlan: plan,
            activeWorkout: activeWorkout,
            completedSessions: [completedSession],
            recoveryHistory: [recovery]
        )
    }
}
