import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedDay: WorkoutDay?
    @State private var isAdjustSheetPresented = false

    private var viewModel: PlanViewModel {
        PlanViewModel(store: store)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                actionButtons
                SectionHeader(title: "Weekly plan", subtitle: "Tap any day to review the workout and swap exercises.")

                ForEach(viewModel.orderedDays) { day in
                    Button {
                        selectedDay = day
                    } label: {
                        dayCard(day)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.shell.ignoresSafeArea())
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(day: day)
                .environmentObject(store)
        }
        .sheet(isPresented: $isAdjustSheetPresented) {
            AdjustPlanSheet(
                frequency: viewModel.selectedFrequency,
                location: viewModel.selectedLocation
            )
            .environmentObject(store)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan")
                .font(.largeTitle.bold())
            Text(viewModel.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            SecondaryButton(title: "Adjust My Plan", systemImage: "slider.horizontal.3") {
                isAdjustSheetPresented = true
            }

            SecondaryButton(title: "Swap Exercise", systemImage: "arrow.triangle.2.circlepath") {
                selectedDay = viewModel.orderedDays.first(where: { $0.isRecovery == false })
            }
        }
    }

    private func dayCard(_ day: WorkoutDay) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: day.kind.icon)
                .font(.title3)
                .foregroundStyle(viewModel.isToday(day) ? .white : AppTheme.accent)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(viewModel.isToday(day) ? Color.white.opacity(0.22) : AppTheme.accent.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.weekdayLabel(for: day))
                        .font(.headline)
                    if viewModel.isToday(day) {
                        Text("Today")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.24))
                            )
                    }
                }

                Text(day.title)
                    .font(.title3.bold())
                Text(day.focusArea)
                    .font(.subheadline)
                    .foregroundStyle(viewModel.isToday(day) ? .white.opacity(0.86) : .secondary)
                Text(day.isRecovery ? "20 min" : "\(day.estimatedMinutes) min • \(day.exercises.count) exercises")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(viewModel.isToday(day) ? .white.opacity(0.9) : .secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(viewModel.isToday(day) ? .white.opacity(0.8) : .secondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(viewModel.isToday(day) ? AnyShapeStyle(AppTheme.heroGradient) : AnyShapeStyle(AppTheme.card))
        )
    }
}

private struct DayDetailSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: Exercise?

    let day: WorkoutDay

    private var refreshedDay: WorkoutDay {
        store.workoutPlan?.days.first(where: { $0.id == day.id }) ?? day
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(refreshedDay.title)
                            .font(.largeTitle.bold())
                        Text(refreshedDay.focusArea)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if refreshedDay.isRecovery {
                        EmptyStateView(
                            title: "Recovery block",
                            message: "Keep movement easy today. A walk, mobility circuit, or extra sleep all count.",
                            icon: "figure.cooldown"
                        )
                    } else {
                        ForEach(refreshedDay.exercises) { exercise in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(exercise.name)
                                            .font(.headline)
                                        Text("\(exercise.targetSets) sets • \(exercise.targetReps) reps")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text(exercise.hint)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button("Swap Exercise") {
                                        selectedExercise = exercise
                                    }
                                    .font(.subheadline.weight(.semibold))
                                }

                                Text("Suggested weight: \(exercise.suggestedWeight)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(AppTheme.card)
                            )
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(AppTheme.shell.ignoresSafeArea())
            .navigationTitle("Day Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                SwapExerciseSheet(dayID: refreshedDay.id, exercise: exercise)
                    .environmentObject(store)
            }
        }
    }
}

private struct SwapExerciseSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let dayID: UUID
    let exercise: Exercise

    var body: some View {
        NavigationStack {
            List {
                Section("Substitute options") {
                    ForEach(exercise.alternatives.prefix(3)) { option in
                        Button {
                            FeedbackEngine.impact()
                            store.swapExercise(dayID: dayID, exerciseID: exercise.id, with: option)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(option.name)
                                    .font(.headline)
                                Text("\(option.targetReps) reps • \(option.suggestedWeight)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(option.hint)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Swap Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AdjustPlanSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var frequency: TrainingFrequency
    @State private var location: WorkoutLocation

    init(frequency: TrainingFrequency, location: WorkoutLocation) {
        _frequency = State(initialValue: frequency)
        _location = State(initialValue: location)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Training frequency") {
                    Picker("Training frequency", selection: $frequency) {
                        ForEach(TrainingFrequency.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Workout location") {
                    Picker("Workout location", selection: $location) {
                        ForEach(WorkoutLocation.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Text("Changes regenerate the week so the plan stays simple and easy to scan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Adjust My Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        FeedbackEngine.success()
                        store.updatePlan(frequency: frequency, location: location)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PlanView()
        .environmentObject(AppStore.preview)
}
