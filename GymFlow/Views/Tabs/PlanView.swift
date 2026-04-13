import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedDay: ScheduledWorkoutDay?
    @State private var isAdjustSheetPresented = false

    private var viewModel: PlanViewModel {
        PlanViewModel(store: store)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                actionButtons
                SectionHeader(title: "Weekly plan", subtitle: "Tap any day to review it, then add, edit, swap, or remove exercises.")

                ForEach(viewModel.scheduledDays) { day in
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
            WorkoutCustomizationSheet(date: day.date)
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
        }
    }

    private func dayCard(_ day: ScheduledWorkoutDay) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: day.workoutDay.kind.icon)
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
                    Text(viewModel.dateLabel(for: day))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(viewModel.isToday(day) ? .white.opacity(0.82) : .secondary)
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

                Text(day.workoutDay.title)
                    .font(.title3.bold())
                if day.workoutDay.focusArea.isEmpty == false {
                    Text(day.workoutDay.focusArea)
                        .font(.subheadline)
                        .foregroundStyle(viewModel.isToday(day) ? .white.opacity(0.86) : .secondary)
                }
                Text(day.workoutDay.kind == .run ? "Run session" : (day.workoutDay.exercises.isEmpty ? "Open day" : "\(day.workoutDay.exercises.count) exercises"))
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
