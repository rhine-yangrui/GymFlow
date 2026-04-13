import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var editingExercise: Exercise?
    @State private var isEditingSessionDetails = false
    @State private var isAddingExercise = false
    @State private var sessionPendingDeletion: WorkoutSession?
    @State private var restTimerSeconds: Int?
    @State private var showCelebration = false
    @StateObject private var runViewModel = RunViewModel()
    @State private var showRunSession = false

    private var viewModel: TodayViewModel {
        TodayViewModel(store: store)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                streakBanner
                headerCard
                bodyContent
                if viewModel.completedSessionsToday.isEmpty == false || viewModel.runsToday.isEmpty == false {
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
        .sheet(isPresented: $isEditingSessionDetails) {
            SessionDetailsSheet(date: .now, workoutDay: viewModel.todayPlan)
                .environmentObject(store)
        }
        .sheet(isPresented: $isAddingExercise) {
            ExerciseEditorSheet(date: .now, existingExercise: nil)
                .environmentObject(store)
        }
        .sheet(isPresented: Binding(
            get: { restTimerSeconds != nil },
            set: { if $0 == false { restTimerSeconds = nil } }
        )) {
            if let seconds = restTimerSeconds {
                RestTimerView(
                    totalSeconds: seconds,
                    onComplete: {},
                    onDismiss: { restTimerSeconds = nil }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .confirmationDialog(
            "Delete training record?",
            isPresented: Binding(
                get: { sessionPendingDeletion != nil },
                set: { if $0 == false { sessionPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let sessionPendingDeletion else { return }
                FeedbackEngine.impact()
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.deleteCompletedSession(sessionPendingDeletion.id)
                }
                self.sessionPendingDeletion = nil
            }

            Button("Cancel", role: .cancel) {
                sessionPendingDeletion = nil
            }
        } message: {
            Text("This removes the saved session and any progress derived from it.")
        }
        .onChange(of: store.activeWorkout?.completedSetCount ?? 0) { _, _ in
            triggerCelebrationIfComplete()
        }
        .fullScreenCover(isPresented: $showRunSession) {
            RunSessionCover(viewModel: runViewModel)
        }
        .onChange(of: runViewModel.runState) { _, newState in
            if newState == .idle && showRunSession {
                showRunSession = false
            }
        }
        .onAppear { runViewModel.store = store }
    }

    private func triggerCelebrationIfComplete() {
        guard let active = store.activeWorkout, active.totalSetCount > 0 else { return }
        guard active.completedSetCount >= active.totalSetCount else { return }
        guard showCelebration == false else { return }

        FeedbackEngine.success()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showCelebration = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    showCelebration = false
                }
            }
        }
    }

    private var streakBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.accent)

            Text("\(store.currentStreak)-day streak")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()

            Text("Best: \(store.bestStreak) days")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.accent.opacity(0.18))
        )
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(viewModel.greeting)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()
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
                        .scaleEffect(showCelebration ? 1.12 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCelebration)

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

                if showCelebration {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.white)
                        Text("Workout Complete! 💪")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.2))
                    )
                    .transition(.scale.combined(with: .opacity))
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
        } else if viewModel.isRunDay {
            startRunContent
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

            SectionHeader(title: day.title, subtitle: day.focusArea.isEmpty ? "Build the session your own way." : day.focusArea)

            if day.exercises.isEmpty == false {
                ForEach(day.exercises) { exercise in
                    exercisePreviewRow(exercise)
                }
            }

            SecondaryButton(title: "Edit Session Details", systemImage: "square.and.pencil") {
                isEditingSessionDetails = true
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
                        onEffortSelected: { score in
                            FeedbackEngine.impact()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.updateDifficulty(for: exercise.id, score: score)
                            }
                        },
                        onEdit: {
                            editingExercise = exercise
                        },
                        onStartRest: {
                            FeedbackEngine.impact()
                            restTimerSeconds = state.breakTargetSeconds
                        }
                    )
                }
            }

            SecondaryButton(title: "Edit Session Details", systemImage: "square.and.pencil") {
                isEditingSessionDetails = true
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

                        Spacer(minLength: 0)

                        Button {
                            sessionPendingDeletion = session
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.danger)
                                .frame(width: 38, height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AppTheme.danger.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
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

            ForEach(viewModel.runsToday) { run in
                todayRunCard(run)
            }
        }
    }

    // MARK: - Run day content

    private var startRunContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            EmptyStateView(
                title: "Run day",
                message: "Pick a mode and tap Start. Pace, distance, and splits are tracked in real time.",
                icon: "figure.run"
            )

            runModeSelector

            runGoalControls

            PrimaryButton(title: "Start Run", systemImage: "play.fill") {
                FeedbackEngine.impact()
                runViewModel.store = store
                runViewModel.startRun()
                showRunSession = true
            }

            SecondaryButton(title: "Edit Session Details", systemImage: "square.and.pencil") {
                isEditingSessionDetails = true
            }
        }
    }

    private var runModeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RunMode.allCases) { mode in
                    let isSelected = runViewModel.selectedMode == mode
                    Button {
                        FeedbackEngine.impact()
                        runViewModel.selectedMode = mode
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.caption.weight(.semibold))
                            Text(mode.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isSelected ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.card))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var runGoalControls: some View {
        switch runViewModel.selectedMode {
        case .distanceGoal:
            runGoalCard(
                title: "Distance goal",
                value: String(format: "%.1f km", runViewModel.distanceGoalKm),
                range: 1...20,
                step: 0.5,
                binding: $runViewModel.distanceGoalKm
            )
        case .timeGoal:
            runGoalCard(
                title: "Time goal",
                value: "\(Int(runViewModel.timeGoalMinutes)) min",
                range: 5...120,
                step: 5,
                binding: $runViewModel.timeGoalMinutes
            )
        case .freeRun, .intervals:
            EmptyView()
        }
    }

    private func runGoalCard(title: String, value: String, range: ClosedRange<Double>, step: Double, binding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .monospacedDigit()
            }
            Slider(value: binding, in: range, step: step)
                .tint(AppTheme.accent)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func todayRunCard(_ run: RunRecord) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.accent)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Run")
                    .font(.title3.bold())
                HStack(spacing: 12) {
                    Label("\(run.formattedDistanceKm) km", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    Label(run.formattedDuration, systemImage: "clock")
                    Label("\(run.formattedPace)/km", systemImage: "speedometer")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.success)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var recoveryDayContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            EmptyStateView(
                title: "Recovery matters too",
                message: "A lighter day can support long-term consistency. If you want to train anyway, add exercises for today and make it your own.",
                icon: "figure.cooldown"
            )

            SecondaryButton(title: "Edit Session Details", systemImage: "square.and.pencil") {
                isEditingSessionDetails = true
            }

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
                if exercise.muscleGroups.isEmpty == false {
                    MuscleGroupTagRow(groups: exercise.muscleGroups)
                        .padding(.top, 2)
                }
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

struct RunSessionCover: View {
    @ObservedObject var viewModel: RunViewModel

    var body: some View {
        ZStack {
            switch viewModel.runState {
            case .idle:
                EmptyView()
            case .countdown, .active, .paused:
                ActiveRunView(viewModel: viewModel)
                    .transition(.opacity)
            case .completed:
                RunSummaryView(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.runState)
    }
}

#Preview {
    TodayView()
        .environmentObject(AppStore.preview)
}
