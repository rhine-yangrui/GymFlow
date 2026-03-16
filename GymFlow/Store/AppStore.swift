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
    @Published private(set) var dailyOverrides: [DailyWorkoutOverride] = [] {
        didSet { save(dailyOverrides, for: .dailyOverrides) }
    }
    @Published private(set) var defaultWorkoutTemplates: [DefaultWorkoutTemplate] = [] {
        didSet { save(defaultWorkoutTemplates, for: .defaultWorkoutTemplates) }
    }
    @Published private(set) var savedTopicOptions: [String] = [] {
        didSet { save(savedTopicOptions, for: .savedTopicOptions) }
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
        case dailyOverrides = "gymflow.dailyOverrides"
        case defaultWorkoutTemplates = "gymflow.defaultWorkoutTemplates"
        case savedTopicOptions = "gymflow.savedTopicOptions"
        case recoveryHistory = "gymflow.recoveryHistory"
    }

    private static let builtInTopics = [
        "Push",
        "Pull",
        "Legs",
        "Upper",
        "Lower",
        "Full Body",
        "Conditioning",
        "Recovery",
        "Open Session"
    ]

    init(defaults: UserDefaults = .standard, preview: Bool = false) {
        self.defaults = defaults

        if preview {
            let sample = AppStore.makePreviewState()
            userProfile = sample.userProfile
            workoutPlan = sample.workoutPlan
            activeWorkout = sample.activeWorkout
            completedSessions = sample.completedSessions
            dailyOverrides = sample.dailyOverrides
            defaultWorkoutTemplates = sample.defaultWorkoutTemplates
            savedTopicOptions = sample.savedTopicOptions
            recoveryHistory = sample.recoveryHistory
        } else {
            userProfile = load(UserProfile.self, for: .userProfile)
            workoutPlan = load(WorkoutPlan.self, for: .workoutPlan)
            activeWorkout = load(ActiveWorkout.self, for: .activeWorkout)
            completedSessions = load([WorkoutSession].self, for: .completedSessions) ?? []
            dailyOverrides = load([DailyWorkoutOverride].self, for: .dailyOverrides) ?? []
            defaultWorkoutTemplates = load([DefaultWorkoutTemplate].self, for: .defaultWorkoutTemplates) ?? []
            savedTopicOptions = load([String].self, for: .savedTopicOptions) ?? []
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
        dailyOverrides = []
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
        dailyOverrides = []
    }

    func todayPlan(referenceDate: Date = .now) -> WorkoutDay? {
        workoutDay(for: referenceDate)
    }

    func workoutDay(for date: Date) -> WorkoutDay? {
        let normalizedDate = normalized(date)

        if let override = dailyOverrides.first(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
            return override.workoutDay
        }

        return baseWorkoutDay(for: normalizedDate)
    }

    func isCustomizedWorkout(on date: Date = .now) -> Bool {
        let normalizedDate = normalized(date)
        return dailyOverrides.contains(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) })
    }

    func weeklySchedule(referenceDate: Date = .now) -> [ScheduledWorkoutDay] {
        weekDates(containing: referenceDate).compactMap { date in
            guard let workoutDay = workoutDay(for: date) else { return nil }

            return ScheduledWorkoutDay(
                date: normalized(date),
                workoutDay: workoutDay,
                isCustomized: isCustomizedWorkout(on: date)
            )
        }
    }

    func topicOptions() -> [String] {
        var seen: Set<String> = []
        var result: [String] = []

        let generatedTopics = workoutPlan?.days
            .filter { $0.exercises.isEmpty == false }
            .map(\.title) ?? []

        for topic in Self.builtInTopics + generatedTopics + savedTopicOptions + defaultWorkoutTemplates.map(\.title) {
            let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = normalizedTopicKey(trimmedTopic)
            guard trimmedTopic.isEmpty == false, seen.contains(key) == false else { continue }
            seen.insert(key)
            result.append(trimmedTopic)
        }

        return result
    }

    func defaultWorkoutTemplate(for topic: String) -> DefaultWorkoutTemplate? {
        let key = normalizedTopicKey(topic)
        guard key.isEmpty == false else { return nil }
        if let savedTemplate = defaultWorkoutTemplates.first(where: { $0.topicKey == key }) {
            return savedTemplate
        }

        return generatedWorkoutTemplate(for: key)
    }

    func hasDefaultWorkoutTemplate(for topic: String) -> Bool {
        defaultWorkoutTemplate(for: topic) != nil
    }

    func suggestedFocusArea(for topic: String) -> String {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTopic.isEmpty == false else { return "" }

        if let template = defaultWorkoutTemplate(for: trimmedTopic) {
            return template.focusArea
        }

        switch normalizedTopicKey(trimmedTopic) {
        case "push":
            return "Chest, shoulders, and triceps"
        case "pull":
            return "Back, posture, and upper-arm support"
        case "legs":
            return "Quads, glutes, and lower-body stability"
        case "upper":
            return "Balanced upper-body strength"
        case "lower":
            return "Lower-body strength and support work"
        case "full body":
            return "Fast full-body work with low decision fatigue"
        case "conditioning":
            return "Short conditioning and core support"
        case "recovery":
            return "Recovery and light movement"
        case "open session":
            return ""
        default:
            return ""
        }
    }

    func activeWorkoutForToday(referenceDate: Date = .now) -> ActiveWorkout? {
        guard let activeWorkout else { return nil }
        return calendar.isDate(activeWorkout.date, inSameDayAs: referenceDate) ? activeWorkout : nil
    }

    func completedSession(on date: Date = .now) -> WorkoutSession? {
        completedSessions(on: date).first
    }

    func completedSessions(on date: Date = .now) -> [WorkoutSession] {
        completedSessions
            .filter { calendar.isDate($0.completedAt, inSameDayAs: date) }
            .sorted { $0.completedAt > $1.completedAt }
    }

    func deleteCompletedSession(_ sessionID: UUID) {
        completedSessions = completedSessions
            .filter { $0.id != sessionID }
            .sorted { $0.completedAt > $1.completedAt }
    }

    func startWorkout(on date: Date = .now) {
        guard activeWorkoutForToday(referenceDate: date) == nil else { return }
        guard let workoutDay = workoutDay(for: date) else { return }
        guard workoutDay.exercises.isEmpty == false else { return }

        activeWorkout = ActiveWorkout(
            dayID: workoutDay.id,
            dayTitle: workoutDay.title,
            date: normalized(date),
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
        activeWorkout.exerciseStates[index].phaseStartedAt = nil
        activeWorkout.exerciseStates[index].lastSetDuration = nil
        activeWorkout.exerciseStates[index].liveStatus = activeWorkout.exerciseStates[index].completedSets >= activeWorkout.exerciseStates[index].targetSets ? .completed : .ready
        activeWorkout.exerciseStates[index].adjustmentNote = "Set logged. Stay smooth on the next one."

        let exerciseState = activeWorkout.exerciseStates[index]
        let intervalSincePreviousSet = activeWorkout.loggedSets
            .map(\.completedAt)
            .max()
            .map { date.timeIntervalSince($0) }

        activeWorkout.loggedSets.append(
            LoggedSet(
                exerciseID: exerciseState.id,
                exerciseName: exerciseState.exerciseName,
                completedAt: date,
                reps: exerciseState.targetRepCount,
                weight: exerciseState.currentWeight,
                setDuration: nil,
                intervalSincePreviousSet: intervalSincePreviousSet,
                feedback: exerciseState.lastFeedback
            )
        )

        self.activeWorkout = activeWorkout
    }

    func startTraining(for exerciseID: UUID, at date: Date = .now) {
        guard var activeWorkout = activeWorkoutForToday(referenceDate: date) else { return }
        guard let index = activeWorkout.exerciseStates.firstIndex(where: { $0.id == exerciseID }) else { return }
        guard activeWorkout.exerciseStates[index].completedSets < activeWorkout.exerciseStates[index].targetSets else { return }

        clearOtherActivePhases(in: &activeWorkout, excluding: exerciseID)
        if activeWorkout.exerciseStates[index].liveStatus == .breakTime,
           let phaseStartedAt = activeWorkout.exerciseStates[index].phaseStartedAt {
            activeWorkout.exerciseStates[index].lastBreakDuration = date.timeIntervalSince(phaseStartedAt)
        }
        activeWorkout.exerciseStates[index].liveStatus = .training
        activeWorkout.exerciseStates[index].phaseStartedAt = date
        activeWorkout.exerciseStates[index].adjustmentNote = "Training in progress."
        self.activeWorkout = activeWorkout
    }

    func finishTrainingAndLogSet(for exerciseID: UUID, at date: Date = .now) {
        guard var activeWorkout = activeWorkoutForToday(referenceDate: date) else { return }
        guard let index = activeWorkout.exerciseStates.firstIndex(where: { $0.id == exerciseID }) else { return }
        guard activeWorkout.exerciseStates[index].liveStatus == .training else { return }
        guard activeWorkout.exerciseStates[index].completedSets < activeWorkout.exerciseStates[index].targetSets else { return }

        let setDuration = activeWorkout.exerciseStates[index].phaseStartedAt.map { date.timeIntervalSince($0) }
        activeWorkout.exerciseStates[index].completedSets += 1
        activeWorkout.exerciseStates[index].lastSetDuration = setDuration
        if activeWorkout.exerciseStates[index].completedSets >= activeWorkout.exerciseStates[index].targetSets {
            activeWorkout.exerciseStates[index].phaseStartedAt = nil
            activeWorkout.exerciseStates[index].liveStatus = .completed
            activeWorkout.exerciseStates[index].adjustmentNote = "Exercise complete. Move on when you are ready."
            if let nextIndex = nextUnfinishedExerciseIndex(in: activeWorkout.exerciseStates, after: index) {
                activeWorkout.exerciseStates[nextIndex].phaseStartedAt = date
                activeWorkout.exerciseStates[nextIndex].liveStatus = .breakTime
                activeWorkout.exerciseStates[nextIndex].adjustmentNote = nil
            }
        } else {
            activeWorkout.exerciseStates[index].phaseStartedAt = date
            activeWorkout.exerciseStates[index].liveStatus = .breakTime
            activeWorkout.exerciseStates[index].adjustmentNote = "Break started automatically. Start the next set when you are ready."
        }

        let exerciseState = activeWorkout.exerciseStates[index]
        let intervalSincePreviousSet = activeWorkout.loggedSets
            .map(\.completedAt)
            .max()
            .map { date.timeIntervalSince($0) }

        activeWorkout.loggedSets.append(
            LoggedSet(
                exerciseID: exerciseState.id,
                exerciseName: exerciseState.exerciseName,
                completedAt: date,
                reps: exerciseState.targetRepCount,
                weight: exerciseState.currentWeight,
                setDuration: setDuration,
                intervalSincePreviousSet: intervalSincePreviousSet,
                feedback: exerciseState.lastFeedback
            )
        )

        self.activeWorkout = activeWorkout
    }

    func setBreakTarget(for exerciseID: UUID, seconds: Int) {
        guard var activeWorkout = activeWorkoutForToday() else { return }
        guard let index = activeWorkout.exerciseStates.firstIndex(where: { $0.id == exerciseID }) else { return }

        activeWorkout.exerciseStates[index].breakTargetSeconds = seconds
        self.activeWorkout = activeWorkout
    }

    func updateDifficulty(for exerciseID: UUID, score: Int) {
        guard var activeWorkout = activeWorkoutForToday() else { return }
        guard let index = activeWorkout.exerciseStates.firstIndex(where: { $0.id == exerciseID }) else { return }

        let feedback = EffortFeedback(score: score)
        let currentWeight = activeWorkout.exerciseStates[index].currentWeight
        activeWorkout.exerciseStates[index].currentWeight = adjustedWeight(from: currentWeight, feedback: feedback)
        activeWorkout.exerciseStates[index].lastFeedback = feedback
        activeWorkout.exerciseStates[index].adjustmentNote = feedback.coachingNote

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

        completedSessions.insert(session, at: 0)
        completedSessions.sort { $0.completedAt > $1.completedAt }
        self.activeWorkout = nil
    }

    func addExercise(
        on date: Date,
        name: String,
        sets: Int,
        reps: String,
        weight: String,
        hint: String
    ) {
        guard var workoutDay = editableWorkoutDay(for: date) else { return }

        workoutDay.exercises.append(
            Exercise(
                name: name,
                targetSets: max(sets, 1),
                targetReps: reps,
                suggestedWeight: weight,
                hint: hint,
                alternatives: genericAlternatives(for: name, reps: reps, weight: weight)
            )
        )

        saveCustomizedWorkoutDay(workoutDay, for: date)
    }

    func updateWorkoutDayDetails(
        on date: Date,
        title: String,
        focusArea: String,
        estimatedMinutes: Int,
        resetPlan: Bool = false,
        saveTopicAsReusable: Bool = false
    ) {
        guard var workoutDay = editableWorkoutDay(for: date) else { return }

        workoutDay.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        workoutDay.focusArea = resetPlan ? "" : focusArea.trimmingCharacters(in: .whitespacesAndNewlines)
        workoutDay.estimatedMinutes = max(estimatedMinutes, 10)
        if resetPlan {
            workoutDay.exercises = []
        }
        workoutDay.kind = resolvedWorkoutKind(
            from: workoutDay.title,
            existingKind: workoutDay.kind
        )

        saveCustomizedWorkoutDay(workoutDay, for: date)

        if saveTopicAsReusable {
            saveTopicOption(workoutDay.title)
        }
    }

    func saveWorkoutDayAsDefaultTemplate(on date: Date, topic: String? = nil) {
        guard let workoutDay = workoutDay(for: date) else { return }

        let title = (topic ?? workoutDay.title).trimmingCharacters(in: .whitespacesAndNewlines)
        let key = normalizedTopicKey(title)
        guard title.isEmpty == false, title != "Open Session" else { return }

        let template = DefaultWorkoutTemplate(
            topicKey: key,
            title: title,
            focusArea: workoutDay.focusArea,
            estimatedMinutes: workoutDay.estimatedMinutes,
            exercises: clonedExercises(workoutDay.exercises)
        )

        if let index = defaultWorkoutTemplates.firstIndex(where: { $0.topicKey == key }) {
            defaultWorkoutTemplates[index] = template
        } else {
            defaultWorkoutTemplates.append(template)
        }

        defaultWorkoutTemplates.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        saveTopicOption(title)
    }

    func applyDefaultWorkoutTemplate(for topic: String, on date: Date) {
        guard let template = defaultWorkoutTemplate(for: topic) else { return }
        guard var workoutDay = editableWorkoutDay(for: date) else { return }

        workoutDay.title = template.title
        workoutDay.focusArea = template.focusArea
        workoutDay.estimatedMinutes = template.estimatedMinutes
        workoutDay.exercises = clonedExercises(template.exercises)
        workoutDay.kind = resolvedWorkoutKind(from: template.title, existingKind: workoutDay.kind)

        saveCustomizedWorkoutDay(workoutDay, for: date)
    }

    func saveTopicOption(_ topic: String) {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = normalizedTopicKey(trimmedTopic)
        guard trimmedTopic.isEmpty == false, key != normalizedTopicKey("Open Session") else { return }
        guard savedTopicOptions.contains(where: { normalizedTopicKey($0) == key }) == false else { return }

        savedTopicOptions.append(trimmedTopic)
        savedTopicOptions.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func updateExercise(
        on date: Date,
        exerciseID: UUID,
        name: String,
        sets: Int,
        reps: String,
        weight: String,
        hint: String
    ) {
        guard var workoutDay = editableWorkoutDay(for: date) else { return }
        guard let exerciseIndex = workoutDay.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }

        workoutDay.exercises[exerciseIndex].name = name
        workoutDay.exercises[exerciseIndex].targetSets = max(sets, 1)
        workoutDay.exercises[exerciseIndex].targetReps = reps
        workoutDay.exercises[exerciseIndex].suggestedWeight = weight
        workoutDay.exercises[exerciseIndex].hint = hint

        if workoutDay.exercises[exerciseIndex].alternatives.isEmpty {
            workoutDay.exercises[exerciseIndex].alternatives = genericAlternatives(for: name, reps: reps, weight: weight)
        }

        saveCustomizedWorkoutDay(workoutDay, for: date)
    }

    func removeExercise(on date: Date, exerciseID: UUID) {
        guard var workoutDay = editableWorkoutDay(for: date) else { return }
        workoutDay.exercises.removeAll { $0.id == exerciseID }
        saveCustomizedWorkoutDay(workoutDay, for: date)
    }

    func swapExercise(on date: Date, exerciseID: UUID, with option: ExerciseSwapOption) {
        guard var workoutDay = editableWorkoutDay(for: date) else { return }
        guard let exerciseIndex = workoutDay.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }

        workoutDay.exercises[exerciseIndex].name = option.name
        workoutDay.exercises[exerciseIndex].targetReps = option.targetReps
        workoutDay.exercises[exerciseIndex].suggestedWeight = option.suggestedWeight
        workoutDay.exercises[exerciseIndex].hint = option.hint
        saveCustomizedWorkoutDay(workoutDay, for: date)
    }

    func resetWorkoutCustomization(for date: Date) {
        dailyOverrides.removeAll { calendar.isDate($0.date, inSameDayAs: date) }

        if let baseWorkoutDay = baseWorkoutDay(for: date) {
            synchronizeActiveWorkoutIfNeeded(for: date, with: baseWorkoutDay)
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
            switch feedback.weightAdjustment {
            case let adjustment where adjustment > 0:
                return "Bodyweight + 10 lb"
            case let adjustment where adjustment < 0:
                return "Assisted bodyweight"
            default:
                return current
            }
        }

        let digits = current.components(separatedBy: CharacterSet.decimalDigits.inverted)
        guard let valueString = digits.first(where: { $0.isEmpty == false }),
              let value = Int(valueString) else {
            return current
        }

        let updatedValue = max(5, value + feedback.weightAdjustment)

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

    private func baseWorkoutDay(for date: Date) -> WorkoutDay? {
        workoutPlan?.day(for: date, calendar: calendar)
    }

    private func editableWorkoutDay(for date: Date) -> WorkoutDay? {
        guard var workoutDay = workoutDay(for: date) else { return nil }
        workoutDay.weekday = calendar.component(.weekday, from: date)
        return workoutDay
    }

    private func saveCustomizedWorkoutDay(_ workoutDay: WorkoutDay, for date: Date) {
        let normalizedDate = normalized(date)
        let normalizedWorkoutDay = normalizedWorkoutDay(workoutDay, for: normalizedDate)

        if let overrideIndex = dailyOverrides.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
            dailyOverrides[overrideIndex].workoutDay = normalizedWorkoutDay
        } else {
            dailyOverrides.append(
                DailyWorkoutOverride(
                    date: normalizedDate,
                    workoutDay: normalizedWorkoutDay
                )
            )
        }

        dailyOverrides.sort { $0.date < $1.date }
        synchronizeActiveWorkoutIfNeeded(for: normalizedDate, with: normalizedWorkoutDay)
    }

    private func normalizedWorkoutDay(_ workoutDay: WorkoutDay, for date: Date) -> WorkoutDay {
        var workoutDay = workoutDay
        workoutDay.weekday = calendar.component(.weekday, from: date)

        if workoutDay.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            workoutDay.title = workoutDay.exercises.isEmpty ? "Open Day" : "Open Session"
        }

        if workoutDay.exercises.isEmpty {
            workoutDay.estimatedMinutes = max(workoutDay.estimatedMinutes, 20)
        } else {
            if workoutDay.title == "Recovery" {
                workoutDay.title = "Open Session"
            }

            workoutDay.estimatedMinutes = max(workoutDay.estimatedMinutes, 12 + (workoutDay.exercises.count * 7))
        }

        workoutDay.kind = resolvedWorkoutKind(
            from: workoutDay.title,
            existingKind: workoutDay.kind
        )

        return workoutDay
    }

    private func resolvedWorkoutKind(from title: String, existingKind: WorkoutDayKind) -> WorkoutDayKind {
        let normalizedTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard normalizedTitle.isEmpty == false else {
            return existingKind
        }

        return WorkoutDayKind.allCases.first(where: { $0.rawValue.lowercased() == normalizedTitle }) ?? .custom
    }

    private func normalizedTopicKey(_ topic: String) -> String {
        topic
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func generatedWorkoutTemplate(for topicKey: String) -> DefaultWorkoutTemplate? {
        let workoutDay: WorkoutDay?

        if let scheduledWorkoutDay = workoutPlan?.days.first(where: {
            normalizedTopicKey($0.title) == topicKey && $0.exercises.isEmpty == false
        }) {
            workoutDay = scheduledWorkoutDay
        } else if let profile = userProfile,
                  let workoutKind = WorkoutDayKind.allCases.first(where: { normalizedTopicKey($0.rawValue) == topicKey }) {
            let generatedDay = WorkoutPlanGenerator.templateDay(for: workoutKind, profile: profile)
            workoutDay = generatedDay.exercises.isEmpty ? nil : generatedDay
        } else {
            workoutDay = nil
        }

        guard let workoutDay else { return nil }

        return DefaultWorkoutTemplate(
            topicKey: topicKey,
            title: workoutDay.title,
            focusArea: workoutDay.focusArea,
            estimatedMinutes: workoutDay.estimatedMinutes,
            exercises: clonedExercises(workoutDay.exercises)
        )
    }

    private func synchronizeActiveWorkoutIfNeeded(for date: Date, with workoutDay: WorkoutDay) {
        guard var activeWorkout else { return }
        guard calendar.isDate(activeWorkout.date, inSameDayAs: date) else { return }

        let existingStates = Dictionary(uniqueKeysWithValues: activeWorkout.exerciseStates.map { ($0.id, $0) })
        let validIDs = Set(workoutDay.exercises.map(\.id))

        activeWorkout.exerciseStates = workoutDay.exercises.map { exercise in
            if var existingState = existingStates[exercise.id] {
                existingState.exerciseName = exercise.name
                existingState.targetSets = exercise.targetSets
                existingState.targetReps = exercise.targetReps
                existingState.hint = exercise.hint
                existingState.currentWeight = exercise.suggestedWeight
                existingState.completedSets = min(existingState.completedSets, exercise.targetSets)
                existingState.liveStatus = existingState.completedSets >= exercise.targetSets ? .completed : (existingState.liveStatus == .completed ? .ready : existingState.liveStatus)
                return existingState
            }

            return ActiveWorkoutExerciseState(
                id: exercise.id,
                exerciseName: exercise.name,
                targetSets: exercise.targetSets,
                targetReps: exercise.targetReps,
                hint: exercise.hint,
                completedSets: 0,
                currentWeight: exercise.suggestedWeight,
                lastFeedback: nil,
                adjustmentNote: nil
            )
        }

        activeWorkout.dayTitle = workoutDay.title
        activeWorkout.estimatedMinutes = workoutDay.estimatedMinutes
        activeWorkout.loggedSets = activeWorkout.loggedSets
            .filter { validIDs.contains($0.exerciseID) }
            .map { loggedSet in
                var loggedSet = loggedSet
                loggedSet.exerciseName = workoutDay.exercises.first(where: { $0.id == loggedSet.exerciseID })?.name ?? loggedSet.exerciseName
                return loggedSet
            }

        self.activeWorkout = activeWorkout
    }

    private func clearOtherActivePhases(in activeWorkout: inout ActiveWorkout, excluding exerciseID: UUID) {
        for index in activeWorkout.exerciseStates.indices where activeWorkout.exerciseStates[index].id != exerciseID {
            activeWorkout.exerciseStates[index].phaseStartedAt = nil
            activeWorkout.exerciseStates[index].liveStatus = activeWorkout.exerciseStates[index].completedSets >= activeWorkout.exerciseStates[index].targetSets ? .completed : .ready
        }
    }

    private func nextUnfinishedExerciseIndex(
        in exerciseStates: [ActiveWorkoutExerciseState],
        after currentIndex: Int
    ) -> Int? {
        guard currentIndex < exerciseStates.endIndex else { return nil }

        for index in exerciseStates.index(after: currentIndex)..<exerciseStates.endIndex {
            if exerciseStates[index].completedSets < exerciseStates[index].targetSets {
                return index
            }
        }

        return nil
    }

    private func weekDates(containing referenceDate: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return [normalized(referenceDate)]
        }

        let dates = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start).map(normalized(_:))
        }
        let mondayFirstOrder = [2, 3, 4, 5, 6, 7, 1]

        return dates.sorted {
            let lhsWeekday = calendar.component(.weekday, from: $0)
            let rhsWeekday = calendar.component(.weekday, from: $1)
            return (mondayFirstOrder.firstIndex(of: lhsWeekday) ?? 0) < (mondayFirstOrder.firstIndex(of: rhsWeekday) ?? 0)
        }
    }

    private func normalized(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func genericAlternatives(for name: String, reps: String, weight: String) -> [ExerciseSwapOption] {
        [
            ExerciseSwapOption(name: "\(name) variation", targetReps: reps, suggestedWeight: weight, hint: "Pick the version that fits the equipment you have today."),
            ExerciseSwapOption(name: "Band option", targetReps: "12-15", suggestedWeight: "Light band", hint: "Useful when you want a lower setup cost."),
            ExerciseSwapOption(name: "Bodyweight option", targetReps: "10-12", suggestedWeight: "Bodyweight", hint: "Keep the tempo controlled and repeatable.")
        ]
    }

    private func clonedExercises(_ exercises: [Exercise]) -> [Exercise] {
        exercises.map { exercise in
            Exercise(
                name: exercise.name,
                targetSets: exercise.targetSets,
                targetReps: exercise.targetReps,
                suggestedWeight: exercise.suggestedWeight,
                hint: exercise.hint,
                alternatives: exercise.alternatives.map {
                    ExerciseSwapOption(
                        name: $0.name,
                        targetReps: $0.targetReps,
                        suggestedWeight: $0.suggestedWeight,
                        hint: $0.hint
                    )
                }
            )
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
        dailyOverrides: [DailyWorkoutOverride],
        defaultWorkoutTemplates: [DefaultWorkoutTemplate],
        savedTopicOptions: [String],
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
        var customizedToday = today
        customizedToday.title = "Custom Push"
        if customizedToday.exercises.isEmpty == false {
            customizedToday.exercises[0].suggestedWeight = "55 lb"
            customizedToday.exercises[0].targetSets = 4
        }
        customizedToday.exercises.append(
            Exercise(
                name: "Cable Lateral Raise",
                targetSets: 2,
                targetReps: "12-15",
                suggestedWeight: "12 lb",
                hint: "Keep the shoulder relaxed and raise smoothly.",
                alternatives: []
            )
        )

        let activeWorkout = ActiveWorkout(
            dayID: customizedToday.id,
            dayTitle: customizedToday.title,
            date: Calendar.current.startOfDay(for: .now),
            startedAt: .now.addingTimeInterval(-900),
            estimatedMinutes: customizedToday.estimatedMinutes,
            exerciseStates: customizedToday.exercises.enumerated().map { index, exercise in
                ActiveWorkoutExerciseState(
                    id: exercise.id,
                    exerciseName: exercise.name,
                    targetSets: exercise.targetSets,
                    targetReps: exercise.targetReps,
                    hint: exercise.hint,
                    completedSets: min(index, 2),
                    currentWeight: exercise.suggestedWeight,
                    lastFeedback: index == 0 ? EffortFeedback(score: 8) : nil,
                    adjustmentNote: index == 0 ? "Try a slightly stronger next set if your form still feels clean." : nil
                )
            },
            loggedSets: [
                LoggedSet(
                    exerciseID: customizedToday.exercises[0].id,
                    exerciseName: customizedToday.exercises[0].name,
                    completedAt: .now.addingTimeInterval(-310),
                    reps: customizedToday.exercises[0].targetRepCount,
                    weight: "50 lb",
                    intervalSincePreviousSet: nil,
                    feedback: nil
                ),
                LoggedSet(
                    exerciseID: customizedToday.exercises[0].id,
                    exerciseName: customizedToday.exercises[0].name,
                    completedAt: .now.addingTimeInterval(-135),
                    reps: customizedToday.exercises[0].targetRepCount,
                    weight: "55 lb",
                    intervalSincePreviousSet: 175,
                    feedback: EffortFeedback(score: 8)
                )
            ]
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
                    intervalSincePreviousSet: 90,
                    feedback: nil
                )
            }
        )

        let override = DailyWorkoutOverride(
            date: Calendar.current.startOfDay(for: .now),
            workoutDay: customizedToday
        )

        let defaultTemplate = DefaultWorkoutTemplate(
            topicKey: "push",
            title: "Push",
            focusArea: "Reusable push session",
            estimatedMinutes: 40,
            exercises: customizedToday.exercises
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
            dailyOverrides: [override],
            defaultWorkoutTemplates: [defaultTemplate],
            savedTopicOptions: ["Arms", "Athletic Conditioning"],
            recoveryHistory: [recovery]
        )
    }
}
