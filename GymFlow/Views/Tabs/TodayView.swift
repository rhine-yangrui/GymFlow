import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var restDuration = 90
    @State private var restEndDate: Date?

    private let restOptions = [60, 90, 120]

    private var viewModel: TodayViewModel {
        TodayViewModel(store: store)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                headerCard
                bodyContent
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.shell.ignoresSafeArea())
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.greeting)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))

            Text("What should you do today?")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text(viewModel.todaySubtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))

            if let activeWorkout = viewModel.activeWorkout {
                HStack {
                    ProgressRing(
                        progress: viewModel.progress,
                        valueText: "\(Int(viewModel.progress * 100))%",
                        caption: "Today"
                    )
                    .frame(width: 96, height: 96)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(activeWorkout.dayTitle)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("\(activeWorkout.estimatedMinutes) min planned")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(viewModel.encouragement)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppTheme.heroGradient)
        )
    }

    @ViewBuilder
    private var bodyContent: some View {
        if let completedSession = viewModel.completedSession {
            completedWorkoutCard(completedSession)
        } else if let activeWorkout = viewModel.activeWorkout {
            activeWorkoutContent(activeWorkout)
        } else if let todayPlan = viewModel.todayPlan, todayPlan.isRecovery == false {
            startWorkoutContent(todayPlan)
        } else {
            recoveryDayContent
        }
    }

    private func startWorkoutContent(_ day: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            EmptyStateView(
                title: "Start today with one tap",
                message: "Your \(day.title.lowercased()) session is ready. You do not need to plan anything else first.",
                icon: "figure.strengthtraining.traditional"
            )

            SectionHeader(title: day.title, subtitle: "\(day.focusArea) • About \(day.estimatedMinutes) min")

            ForEach(day.exercises.prefix(3)) { exercise in
                exercisePreviewRow(exercise)
            }

            PrimaryButton(title: "Start Today’s Workout", systemImage: "play.fill") {
                FeedbackEngine.impact()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    store.startWorkout()
                }
            }
        }
    }

    private func activeWorkoutContent(_ activeWorkout: ActiveWorkout) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: activeWorkout.dayTitle, subtitle: viewModel.encouragement)

            ForEach(displayExercises(for: activeWorkout)) { exercise in
                let state = activeWorkout.exerciseStates.first(where: { $0.id == exercise.id })

                ExerciseCard(
                    exercise: exercise,
                    completedSets: state?.completedSets ?? 0,
                    currentWeight: state?.currentWeight ?? exercise.suggestedWeight,
                    lastFeedback: state?.lastFeedback,
                    adjustmentNote: state?.adjustmentNote,
                    onLogSet: {
                        FeedbackEngine.impact()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            store.logSet(for: exercise.id)
                        }
                    },
                    onTooEasy: {
                        FeedbackEngine.impact()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.updateDifficulty(for: exercise.id, feedback: .tooEasy)
                        }
                    },
                    onTooHard: {
                        FeedbackEngine.impact()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.updateDifficulty(for: exercise.id, feedback: .tooHard)
                        }
                    }
                )
            }

            restTimerCard

            PrimaryButton(title: "Finish Workout", systemImage: "checkmark.circle.fill") {
                FeedbackEngine.success()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    store.finishWorkout()
                }
            }
        }
    }

    private func completedWorkoutCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                ProgressRing(progress: 1, valueText: "Done", caption: "Today")
                    .frame(width: 92, height: 92)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Today’s workout is finished")
                        .font(.title3.bold())
                    Text("\(session.dayTitle) completed with \(session.loggedSets.count) logged sets.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Nice work. Recovery and consistency matter just as much as intensity.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppTheme.card)
            )

            SectionHeader(title: "Session recap", subtitle: "A quick look at what you finished today.")

            ForEach(session.loggedSets.prefix(4)) { loggedSet in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loggedSet.exerciseName)
                            .font(.headline)
                        Text("\(loggedSet.reps) reps • \(loggedSet.weight)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppTheme.card)
                )
            }
        }
    }

    private var recoveryDayContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            EmptyStateView(
                title: "Recovery matters too",
                message: "A lighter day can support long-term consistency. Use Recovery to check in before deciding how hard to push.",
                icon: "figure.cooldown"
            )

            if let recommendation = store.latestRecoveryCheckIn()?.recommendation {
                RecoveryRecommendationCard(recommendation: recommendation)
            }
        }
    }

    private var restTimerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Rest timer", subtitle: "Keep the pace moving without checking the clock.")

            HStack(spacing: 10) {
                ForEach(restOptions, id: \.self) { option in
                    Button {
                        restDuration = option
                        startRestTimer()
                    } label: {
                        Text("\(option)s")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(restDuration == option ? .white : Color.primary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(restDuration == option ? AppTheme.accent : Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(timerLabel(at: context.date))
                    .font(.title3.bold())
                    .foregroundStyle(restRemaining(at: context.date) > 0 ? AppTheme.accent : .primary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func exercisePreviewRow(_ exercise: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text("\(exercise.targetSets) sets • \(exercise.targetReps) reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .foregroundStyle(AppTheme.accent)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func startRestTimer() {
        FeedbackEngine.impact()
        restEndDate = Date().addingTimeInterval(TimeInterval(restDuration))
    }

    private func restRemaining(at date: Date) -> Int {
        guard let restEndDate else { return 0 }
        return max(Int(restEndDate.timeIntervalSince(date).rounded(.up)), 0)
    }

    private func timerLabel(at date: Date) -> String {
        let remaining = restRemaining(at: date)
        guard remaining > 0 else { return "Timer ready" }
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d left", minutes, seconds)
    }

    private func displayExercises(for activeWorkout: ActiveWorkout) -> [Exercise] {
        if let planDay = store.workoutPlan?.days.first(where: { $0.id == activeWorkout.dayID }) {
            return planDay.exercises
        }

        return activeWorkout.exerciseStates.map {
            Exercise(
                id: $0.id,
                name: $0.exerciseName,
                targetSets: $0.targetSets,
                targetReps: $0.targetReps,
                suggestedWeight: $0.currentWeight,
                hint: $0.hint,
                alternatives: []
            )
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(AppStore.preview)
}
