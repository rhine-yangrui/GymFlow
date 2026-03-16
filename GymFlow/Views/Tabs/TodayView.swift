import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editingExercise: Exercise?
    @State private var isAddingExercise = false

    private var viewModel: TodayViewModel {
        TodayViewModel(store: store)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                headerCard
                bodyContent
                if viewModel.completedSessionsToday.isEmpty == false {
                    completedSessionsSection
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.shell.ignoresSafeArea())
        .sheet(item: $editingExercise) { exercise in
            ExerciseEditorSheet(date: .now, existingExercise: exercise)
                .environmentObject(store)
        }
        .sheet(isPresented: $isAddingExercise) {
            ExerciseEditorSheet(date: .now, existingExercise: nil)
                .environmentObject(store)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(viewModel.greeting)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                if viewModel.isCustomizedToday {
                    Text("Customized")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.18))
                        )
                }
            }

            Text("What should you do today?")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text(viewModel.todaySubtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))

            if let activeWorkout = viewModel.activeWorkout {
                TimelineView(.periodic(from: .now, by: 1)) { context in
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
                            Text("Workout timer: \(intervalString(from: context.date.timeIntervalSince(activeWorkout.startedAt)))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(viewModel.encouragement)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.82))
                        }
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
        if let activeWorkout = viewModel.activeWorkout {
            activeWorkoutContent(activeWorkout)
        } else if let todayPlan = viewModel.todayPlan, todayPlan.isRecovery == false || todayPlan.exercises.isEmpty == false {
            startWorkoutContent(todayPlan)
        } else {
            recoveryDayContent
        }
    }

    private func startWorkoutContent(_ day: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            EmptyStateView(
                title: day.exercises.isEmpty ? "Build today’s workout first" : "Start today with one tap",
                message: day.exercises.isEmpty
                    ? "Add your own exercises or edit the ones you want, then start the session."
                    : viewModel.completedSessionsToday.isEmpty
                        ? "Every exercise below can be edited before you begin, so today’s workout can match what you actually want to do."
                        : "You can still edit today’s setup and start another session whenever you want.",
                icon: day.exercises.isEmpty ? "slider.horizontal.3" : "figure.strengthtraining.traditional"
            )

            SectionHeader(title: day.title, subtitle: "\(day.focusArea) • About \(day.estimatedMinutes) min")

            if day.exercises.isEmpty == false {
                ForEach(day.exercises) { exercise in
                    exercisePreviewRow(exercise)
                }
            }

            SecondaryButton(title: "Add Exercise", systemImage: "plus") {
                isAddingExercise = true
            }

            PrimaryButton(title: "Start Today’s Workout", systemImage: "play.fill") {
                FeedbackEngine.impact()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    store.startWorkout()
                }
            }
            .disabled(day.exercises.isEmpty)
            .opacity(day.exercises.isEmpty ? 0.45 : 1)
        }
    }

    private func activeWorkoutContent(_ activeWorkout: ActiveWorkout) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: activeWorkout.dayTitle, subtitle: "Each exercise now carries its own status, set timer, break timer, and quick edit button.")

            ForEach(displayExercises(for: activeWorkout)) { exercise in
                if let state = activeWorkout.exerciseStates.first(where: { $0.id == exercise.id }) {
                    ExerciseCard(
                        exercise: exercise,
                        completedSets: state.completedSets,
                        currentWeight: state.currentWeight,
                        lastFeedback: state.lastFeedback,
                        adjustmentNote: state.adjustmentNote,
                        liveStatus: state.liveStatus,
                        phaseStartedAt: state.phaseStartedAt,
                        lastSetDuration: state.lastSetDuration,
                        lastBreakDuration: state.lastBreakDuration,
                        breakTargetSeconds: state.breakTargetSeconds,
                        onStartTraining: {
                            FeedbackEngine.impact()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.startTraining(for: exercise.id)
                            }
                        },
                        onFinishSet: {
                            FeedbackEngine.success()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.finishTrainingAndLogSet(for: exercise.id)
                            }
                        },
                        onStartBreak: {
                            FeedbackEngine.impact()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.startBreak(for: exercise.id)
                            }
                        },
                        onEndBreak: {
                            FeedbackEngine.impact()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.endBreak(for: exercise.id)
                            }
                        },
                        onBreakTargetSelected: { seconds in
                            store.setBreakTarget(for: exercise.id, seconds: seconds)
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
                        },
                        onEdit: {
                            editingExercise = exercise
                        }
                    )
                }
            }

            SecondaryButton(title: "Add Exercise", systemImage: "plus") {
                isAddingExercise = true
            }

            PrimaryButton(title: "Finish Workout", systemImage: "checkmark.circle.fill") {
                FeedbackEngine.success()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    store.finishWorkout()
                }
            }
        }
    }

    private var completedSessionsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Today’s sessions",
                subtitle: "Finished sessions stay here, and you can still edit the workout and start another one."
            )

            ForEach(viewModel.completedSessionsToday) { session in
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        ProgressRing(progress: 1, valueText: "Done", caption: "Session")
                            .frame(width: 82, height: 82)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.dayTitle)
                                .font(.title3.bold())
                            Text(
                                "\(session.loggedSets.count) logged sets • \(intervalString(from: session.completedAt.timeIntervalSince(session.startedAt))) total • finished \(session.completedAt.formatted(date: .omitted, time: .shortened))"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            Text("Use this as a recap, then build the next session however you want.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(AppTheme.card)
                    )

                    ForEach(session.loggedSets.prefix(3)) { loggedSet in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(loggedSet.exerciseName)
                                    .font(.headline)
                                Text(sessionLine(for: loggedSet))
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
        }
    }

    private var recoveryDayContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            EmptyStateView(
                title: "Recovery matters too",
                message: "A lighter day can support long-term consistency. If you want to train anyway, add exercises for today and make it your own.",
                icon: "figure.cooldown"
            )

            SecondaryButton(title: "Add Exercise", systemImage: "plus") {
                isAddingExercise = true
            }

            if let recommendation = store.latestRecoveryCheckIn()?.recommendation {
                RecoveryRecommendationCard(recommendation: recommendation)
            }
        }
    }

    private func exercisePreviewRow(_ exercise: Exercise) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text("\(exercise.targetSets) sets • \(exercise.targetReps) reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(exercise.suggestedWeight)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            Spacer()

            Button {
                editingExercise = exercise
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func sessionLine(for loggedSet: LoggedSet) -> String {
        var parts = ["\(loggedSet.reps) reps", loggedSet.weight]

        if let setDuration = loggedSet.setDuration {
            parts.append("set \(intervalString(from: setDuration))")
        }

        if let intervalSincePreviousSet = loggedSet.intervalSincePreviousSet {
            parts.append("gap \(intervalString(from: intervalSincePreviousSet))")
        }

        return parts.joined(separator: " • ")
    }

    private func intervalString(from interval: TimeInterval) -> String {
        let totalSeconds = max(Int(interval.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func displayExercises(for activeWorkout: ActiveWorkout) -> [Exercise] {
        if let workoutDay = store.workoutDay(for: activeWorkout.date) {
            return workoutDay.exercises
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
