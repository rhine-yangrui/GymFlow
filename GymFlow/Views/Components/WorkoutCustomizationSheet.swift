import SwiftUI

struct WorkoutCustomizationSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var editingExercise: Exercise?
    @State private var isAddingExercise = false
    @State private var isEditingSessionDetails = false
    @State private var exercisePendingDeletion: Exercise?

    let date: Date

    private static let headerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    private var workoutDay: WorkoutDay? {
        store.workoutDay(for: date)
    }

    private var isCustomized: Bool {
        store.isCustomizedWorkout(on: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard

                    if let workoutDay {
                        if workoutDay.exercises.isEmpty {
                            EmptyStateView(
                                title: "No exercises added yet",
                                message: "Set the day topic however you want, then add exercises and tune the sets, reps, and weight targets before you start.",
                                icon: "list.bullet.clipboard"
                            )
                        } else {
                            ForEach(workoutDay.exercises) { exercise in
                                exerciseRow(exercise)
                            }
                        }
                    } else {
                        EmptyStateView(
                            title: "No workout available",
                            message: "Generate a plan first, then customize the day from here.",
                            icon: "calendar.badge.exclamationmark"
                        )
                    }

                    VStack(spacing: 12) {
                        if let workoutDay, workoutDay.title != "Open Session", workoutDay.exercises.isEmpty == false {
                            SecondaryButton(title: "Save Topic Default", systemImage: "square.and.arrow.down") {
                                FeedbackEngine.success()
                                store.saveWorkoutDayAsDefaultTemplate(on: date)
                            }
                        }

                        if let workoutDay, store.hasDefaultWorkoutTemplate(for: workoutDay.title) {
                            SecondaryButton(title: "Apply Saved Default", systemImage: "arrow.down.doc") {
                                FeedbackEngine.impact()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    store.applyDefaultWorkoutTemplate(for: workoutDay.title, on: date)
                                }
                            }
                        }

                        SecondaryButton(title: "Add Exercise", systemImage: "plus") {
                            isAddingExercise = true
                        }

                        if isCustomized {
                            SecondaryButton(title: "Reset to Plan", systemImage: "arrow.uturn.backward") {
                                FeedbackEngine.impact()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    store.resetWorkoutCustomization(for: date)
                                }
                            }
                        }
                    }

                    Text("Changes apply only to \(Self.headerFormatter.string(from: date)).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(AppTheme.shell.ignoresSafeArea())
            .navigationTitle("Customize Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingExercise) { exercise in
                ExerciseEditorSheet(date: date, existingExercise: exercise)
                    .environmentObject(store)
            }
            .sheet(isPresented: $isEditingSessionDetails) {
                SessionDetailsSheet(date: date, workoutDay: workoutDay)
                    .environmentObject(store)
            }
            .sheet(isPresented: $isAddingExercise) {
                ExerciseEditorSheet(date: date, existingExercise: nil)
                    .environmentObject(store)
            }
            .confirmationDialog(
                "Remove Exercise?",
                isPresented: Binding(
                    get: { exercisePendingDeletion != nil },
                    set: { if $0 == false { exercisePendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    guard let exercisePendingDeletion else { return }
                    FeedbackEngine.impact()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.removeExercise(on: date, exerciseID: exercisePendingDeletion.id)
                    }
                    self.exercisePendingDeletion = nil
                }

                Button("Cancel", role: .cancel) {
                    exercisePendingDeletion = nil
                }
            } message: {
                Text("If this exercise is already active today, its in-progress sets will be removed too.")
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(Self.headerFormatter.string(from: date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            if let workoutDay {
                Text(workoutDay.title)
                    .font(.title2.bold())
                if workoutDay.focusArea.isEmpty == false {
                    Text(workoutDay.focusArea)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("\(workoutDay.exercises.count) exercises")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            Button {
                isEditingSessionDetails = true
            } label: {
                Label("Edit Session Details", systemImage: "square.and.pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)

            if isToday, store.activeWorkoutForToday() != nil {
                Label("Edits sync into the active workout right away.", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                    Text("\(exercise.targetSets) sets • \(exercise.targetReps) reps • \(exercise.suggestedWeight)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(exercise.hint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    editingExercise = exercise
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.accent.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                actionChip(title: "Edit", systemImage: "slider.horizontal.3") {
                    editingExercise = exercise
                }

                actionChip(title: "Remove", systemImage: "trash") {
                    exercisePendingDeletion = exercise
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }

    private func actionChip(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }
}

struct SessionDetailsSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let workoutDay: WorkoutDay?

    @State private var selectedTopic: String
    @State private var customTopic: String
    @State private var focusArea: String
    @State private var saveTopicAsReusable = false
    @State private var saveAsDefaultTemplate = false

    init(date: Date, workoutDay: WorkoutDay?) {
        self.date = date
        self.workoutDay = workoutDay
        let currentTitle = workoutDay?.title ?? "Open Session"
        let currentFocus = workoutDay?.focusArea ?? "Flexible session for today"
        let usesCustomTopic = SessionDetailsSheet.defaultTopics.contains(currentTitle) == false

        _selectedTopic = State(initialValue: usesCustomTopic ? Self.customTopicLabel : currentTitle)
        _customTopic = State(initialValue: usesCustomTopic ? currentTitle : "")
        _focusArea = State(initialValue: currentFocus)
    }

    private var resolvedTopic: String {
        let topic = selectedTopic == Self.customTopicLabel ? customTopic : selectedTopic
        return topic.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var existingTopic: String {
        workoutDay?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var topicOptions: [String] {
        store.topicOptions() + [Self.customTopicLabel]
    }

    private var isValid: Bool {
        resolvedTopic.isEmpty == false
    }

    private var canSaveAsDefault: Bool {
        resolvedTopic.isEmpty == false &&
        resolvedTopic != "Open Session" &&
        (workoutDay?.exercises.isEmpty == false) &&
        shouldResetPlan == false
    }

    private var canApplySavedDefault: Bool {
        store.hasDefaultWorkoutTemplate(for: resolvedTopic)
    }

    private var selectedTemplate: DefaultWorkoutTemplate? {
        let topic = resolvedTopic
        guard topic.isEmpty == false, topic != "Open Session" else { return nil }
        return store.defaultWorkoutTemplate(for: topic)
    }

    private var shouldResetPlan: Bool {
        resolvedTopic != existingTopic &&
        (resolvedTopic == "Open Session" || selectedTopic == Self.customTopicLabel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session topic") {
                    Picker("Topic", selection: $selectedTopic) {
                        ForEach(topicOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)

                    if selectedTopic == Self.customTopicLabel {
                        TextField("Custom topic", text: $customTopic)
                    }
                }

                Section("Focus") {
                    TextField("What is this session about?", text: $focusArea, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Topic guide") {
                    if resolvedTopic == "Open Session" {
                        Text("Open Session clears the current exercise list so you can build a blank session from scratch.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if let selectedTemplate, selectedTemplate.exercises.isEmpty == false {
                        Text(selectedTemplate.focusArea)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(Array(selectedTemplate.exercises.prefix(4))) { exercise in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(exercise.targetSets) sets • \(exercise.targetReps) reps • \(exercise.suggestedWeight)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }

                        if selectedTemplate.exercises.count > 4 {
                            Text("+ \(selectedTemplate.exercises.count - 4) more exercises in the default plan")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No saved default exists for this topic yet. You can still set the topic and build the session manually.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Reusable options") {
                    if selectedTopic == Self.customTopicLabel || SessionDetailsSheet.defaultTopics.contains(resolvedTopic) == false {
                        Toggle("Save this topic as a regular option", isOn: $saveTopicAsReusable)
                    }

                    Toggle("Save this session as the default for this topic", isOn: $saveAsDefaultTemplate)
                        .disabled(canSaveAsDefault == false)

                    if canApplySavedDefault {
                        Button("Apply saved default session") {
                            store.applyDefaultWorkoutTemplate(for: resolvedTopic, on: date)
                            dismiss()
                        }
                    }
                }

                Section {
                    Text("Changing the topic to Open Session or entering a new custom topic clears the current exercise list so you can rebuild from scratch. Standard topic changes keep the exercises in place.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedTopic) {
                syncFocusWithTopic()
            }
            .onChange(of: customTopic) {
                if selectedTopic == Self.customTopicLabel {
                    syncFocusWithTopic()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmedFocus = focusArea.trimmingCharacters(in: .whitespacesAndNewlines)

                        if shouldResetPlan {
                            store.updateWorkoutDayDetails(
                                on: date,
                                title: resolvedTopic,
                                focusArea: trimmedFocus,
                                estimatedMinutes: workoutDay?.estimatedMinutes ?? 35,
                                resetPlan: true,
                                saveTopicAsReusable: saveTopicAsReusable
                            )
                        } else {
                            if resolvedTopic != existingTopic, store.hasDefaultWorkoutTemplate(for: resolvedTopic) {
                                store.applyDefaultWorkoutTemplate(for: resolvedTopic, on: date)
                            }

                            store.updateWorkoutDayDetails(
                                on: date,
                                title: resolvedTopic,
                                focusArea: trimmedFocus,
                                estimatedMinutes: workoutDay?.estimatedMinutes ?? 35,
                                resetPlan: false,
                                saveTopicAsReusable: saveTopicAsReusable
                            )
                        }

                        if saveAsDefaultTemplate && canSaveAsDefault {
                            store.saveWorkoutDayAsDefaultTemplate(on: date, topic: resolvedTopic)
                        }
                        dismiss()
                    }
                    .disabled(isValid == false)
                }
            }
        }
    }

    private func syncFocusWithTopic() {
        let topic = resolvedTopic
        if topic.isEmpty {
            focusArea = ""
            return
        }

        focusArea = store.suggestedFocusArea(for: topic)
    }

    private static let defaultTopics = [
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
    private static let customTopicLabel = "Custom"
}

struct ExerciseEditorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let existingExercise: Exercise?

    @State private var sets: Int
    @State private var selectedExerciseName: String
    @State private var customExerciseName: String
    @State private var selectedRepOption: String
    @State private var customRepOption: String
    @State private var selectedWeightUnit: WeightUnitOption
    @State private var selectedWeightValue: Int
    @State private var hint: String

    private let setOptions = Array(1...8)
    private let repOptions = ["4-6", "6-8", "8-10", "10-12", "12-15", "15-20", "20", "30-45 sec", "Custom"]
    private let exerciseNameOptions = [
        "Bench Press",
        "Incline Dumbbell Press",
        "Chest Press",
        "Shoulder Press",
        "Lat Pulldown",
        "Seated Cable Row",
        "Goblet Squat",
        "Leg Press",
        "Romanian Deadlift",
        "Walking Lunge",
        "Push-Up",
        "Plank",
        "Custom"
    ]
    init(date: Date, existingExercise: Exercise?) {
        self.date = date
        self.existingExercise = existingExercise
        _sets = State(initialValue: existingExercise?.targetSets ?? 3)
        _hint = State(initialValue: existingExercise?.hint ?? "Use a setup that feels realistic for today.")

        let exerciseName = existingExercise?.name ?? ""
        let usesCustomName = exerciseName.isEmpty == false && ExerciseEditorSheet.defaultExerciseNames.contains(exerciseName) == false
        _selectedExerciseName = State(initialValue: usesCustomName ? "Custom" : (exerciseName.isEmpty ? "Bench Press" : exerciseName))
        _customExerciseName = State(initialValue: usesCustomName ? exerciseName : "")

        let repValue = existingExercise?.targetReps ?? "8-10"
        let usesCustomRep = ExerciseEditorSheet.defaultRepOptions.contains(repValue) == false
        _selectedRepOption = State(initialValue: usesCustomRep ? "Custom" : repValue)
        _customRepOption = State(initialValue: usesCustomRep ? repValue : "")

        let parsedWeight = ExerciseEditorSheet.parseWeight(existingExercise?.suggestedWeight ?? "Bodyweight")
        _selectedWeightUnit = State(initialValue: parsedWeight.unit)
        _selectedWeightValue = State(initialValue: parsedWeight.value)
    }

    private var isValid: Bool {
        resolvedExerciseName.isEmpty == false &&
        resolvedReps.isEmpty == false
    }

    private var weightValues: [Int] {
        switch selectedWeightUnit {
        case .bodyweight:
            return []
        case .pounds:
            return Array(stride(from: 5, through: 405, by: 5))
        case .kilograms:
            return Array(1...200)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise name") {
                    Picker("Exercise name", selection: $selectedExerciseName) {
                        ForEach(exerciseNameOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)

                    if selectedExerciseName == "Custom" {
                        TextField("Custom exercise name", text: $customExerciseName)
                    }
                }

                Section("Targets") {
                    Picker("Sets", selection: $sets) {
                        ForEach(setOptions, id: \.self) { option in
                            Text("\(option) sets").tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)

                    Picker("Reps", selection: $selectedRepOption) {
                        ForEach(repOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)

                    if selectedRepOption == "Custom" {
                        TextField("Custom reps", text: $customRepOption)
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("Weight") {
                    Picker("Weight type", selection: $selectedWeightUnit) {
                        ForEach(WeightUnitOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)

                    if selectedWeightUnit != .bodyweight {
                        Picker("Weight amount", selection: $selectedWeightValue) {
                            ForEach(weightValues, id: \.self) { value in
                                Text("\(value) \(selectedWeightUnit.rawValue)").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 110)
                    }
                }

                Section("Coaching hint") {
                    TextField("Hint", text: $hint, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Text("Use this to fine-tune the session for today without regenerating the whole plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let existingExercise {
                    Section {
                        Button("Remove Exercise", role: .destructive) {
                            store.removeExercise(on: date, exerciseID: existingExercise.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(existingExercise == nil ? "Add Exercise" : "Edit Exercise")
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

                        if let existingExercise {
                            store.updateExercise(
                                on: date,
                                exerciseID: existingExercise.id,
                                name: resolvedExerciseName,
                                sets: sets,
                                reps: resolvedReps,
                                weight: resolvedWeight,
                                hint: trimmed(hint)
                            )
                        } else {
                            store.addExercise(
                                on: date,
                                name: resolvedExerciseName,
                                sets: sets,
                                reps: resolvedReps,
                                weight: resolvedWeight,
                                hint: trimmed(hint)
                            )
                        }

                        dismiss()
                    }
                    .disabled(isValid == false)
                }
            }
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var resolvedExerciseName: String {
        selectedExerciseName == "Custom" ? trimmed(customExerciseName) : selectedExerciseName
    }

    private var resolvedReps: String {
        selectedRepOption == "Custom" ? trimmed(customRepOption) : selectedRepOption
    }

    private var resolvedWeight: String {
        switch selectedWeightUnit {
        case .bodyweight:
            return "Bodyweight"
        case .pounds, .kilograms:
            return "\(selectedWeightValue) \(selectedWeightUnit.rawValue)"
        }
    }

    private static let defaultExerciseNames = [
        "Bench Press",
        "Incline Dumbbell Press",
        "Chest Press",
        "Shoulder Press",
        "Lat Pulldown",
        "Seated Cable Row",
        "Goblet Squat",
        "Leg Press",
        "Romanian Deadlift",
        "Walking Lunge",
        "Push-Up",
        "Plank"
    ]

    private static let defaultRepOptions = ["4-6", "6-8", "8-10", "10-12", "12-15", "15-20", "20", "30-45 sec"]

    private static func parseWeight(_ value: String) -> (unit: WeightUnitOption, value: Int) {
        if value.localizedCaseInsensitiveContains("bodyweight") {
            return (.bodyweight, 0)
        }

        let unit: WeightUnitOption = value.localizedCaseInsensitiveContains("kg") ? .kilograms : .pounds
        let digits = value.components(separatedBy: CharacterSet.decimalDigits.inverted)
        let rawAmount = digits.first(where: { $0.isEmpty == false }).flatMap(Int.init) ?? 45

        switch unit {
        case .bodyweight:
            return (.bodyweight, 0)
        case .pounds:
            let rounded = max(5, Int((Double(rawAmount) / 5).rounded()) * 5)
            return (.pounds, rounded)
        case .kilograms:
            return (.kilograms, min(max(rawAmount, 1), 200))
        }
    }
}

#Preview {
    WorkoutCustomizationSheet(date: .now)
        .environmentObject(AppStore.preview)
}

enum WeightUnitOption: String, CaseIterable, Identifiable {
    case bodyweight = "bodyweight"
    case pounds = "lb"
    case kilograms = "kg"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bodyweight:
            return "Bodyweight"
        case .pounds:
            return "Pounds (lb)"
        case .kilograms:
            return "Kilograms (kg)"
        }
    }
}
