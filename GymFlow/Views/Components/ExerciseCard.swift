import SwiftUI

struct ExerciseCard: View {
    @State private var isCustomBreakSheetPresented = false

    var exercise: Exercise
    var completedSets: Int
    var currentWeight: String
    var lastFeedback: EffortFeedback?
    var adjustmentNote: String?
    var liveStatus: ExerciseLiveStatus
    var phaseStartedAt: Date?
    var lastSetDuration: TimeInterval?
    var lastBreakDuration: TimeInterval?
    var breakTargetSeconds: Int
    var onStartTraining: () -> Void
    var onFinishSet: () -> Void
    var onBreakTargetSelected: (Int) -> Void
    var onEffortSelected: (Int) -> Void
    var onEdit: () -> Void

    private let breakOptions = [60, 90, 120]

    private var isComplete: Bool {
        completedSets >= exercise.targetSets
    }

    private var nextSetNumber: Int {
        min(completedSets + 1, exercise.targetSets)
    }

    private var primaryTitle: String {
        switch liveStatus {
        case .training:
            return "Log Set \(nextSetNumber) of \(exercise.targetSets)"
        case .completed:
            return "All Sets Done"
        case .ready, .breakTime:
            return "Start Set \(nextSetNumber) of \(exercise.targetSets)"
        }
    }

    private var usesCustomBreakTarget: Bool {
        breakOptions.contains(breakTargetSeconds) == false
    }

    private var statusColor: Color {
        switch liveStatus {
        case .ready:
            return AppTheme.accent
        case .training:
            return AppTheme.accentWarm
        case .breakTime:
            return AppTheme.warning
        case .completed:
            return AppTheme.success
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.headline)
                    Text("\(exercise.targetSets) sets • \(exercise.targetReps) reps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Suggested weight: \(currentWeight)")
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Button(action: onEdit) {
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

                    Label("\(completedSets)/\(exercise.targetSets)", systemImage: isComplete ? "checkmark.circle.fill" : "circle.dotted")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isComplete ? AppTheme.success : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isComplete ? AppTheme.success.opacity(0.14) : Color.primary.opacity(0.06))
                        )
                }
            }

            Text(adjustmentNote ?? exercise.hint)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            timingBlock

            PrimaryButton(title: primaryTitle, systemImage: liveStatus == .training ? "checkmark.circle.fill" : "bolt.fill") {
                if liveStatus == .training {
                    onFinishSet()
                } else {
                    onStartTraining()
                }
            }
            .disabled(isComplete)
            .opacity(isComplete ? 0.45 : 1)

            effortScale

            if let lastFeedback {
                Label("Last effort: \(lastFeedback.summary)", systemImage: "slider.horizontal.3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .sheet(isPresented: $isCustomBreakSheetPresented) {
            BreakTargetSheet(selectedSeconds: breakTargetSeconds) { seconds in
                onBreakTargetSelected(seconds)
            }
        }
    }

    private var timingBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(liveStatus.rawValue, systemImage: liveStatus == .breakTime ? "pause.circle.fill" : "waveform.path.ecg")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(statusColor.opacity(0.12))
                    )

                Spacer()

                if liveStatus == .completed {
                    Text("Exercise complete")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Set \(nextSetNumber) of \(exercise.targetSets)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            liveTimerCard

            HStack(spacing: 10) {
                summaryPill(title: "Last set", value: intervalLabel(lastSetDuration))
                summaryPill(title: "Last break", value: intervalLabel(lastBreakDuration))
            }

            if liveStatus != .completed {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(breakOptions, id: \.self) { option in
                            Button {
                                onBreakTargetSelected(option)
                            } label: {
                                Text("\(option)s")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(breakTargetSeconds == option ? .white : Color.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 34)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(breakTargetSeconds == option ? AppTheme.accent : Color.primary.opacity(0.06))
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            isCustomBreakSheetPresented = true
                        } label: {
                            Text(usesCustomBreakTarget ? "\(breakTargetSeconds)s" : "Custom")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(usesCustomBreakTarget ? .white : Color.primary)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 34)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(usesCustomBreakTarget ? AppTheme.accent : Color.primary.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    @ViewBuilder
    private var liveTimerCard: some View {
        switch liveStatus {
        case .training:
            phaseCard(
                title: "Training timer",
                subtitle: "Log the set when you finish.",
                tint: AppTheme.accentWarm,
                targetText: nil
            )
        case .breakTime:
            phaseCard(
                title: "Break timer",
                subtitle: "Tap Start Set when you are ready to go again.",
                tint: AppTheme.warning,
                targetText: "Target \(intervalLabel(TimeInterval(breakTargetSeconds)))"
            )
        case .completed:
            phaseSummary(
                title: "Exercise finished",
                subtitle: "All planned sets are logged for this movement."
            )
        case .ready:
            phaseSummary(
                title: "Ready for set \(nextSetNumber)",
                subtitle: "Tap Start Set when you begin. Logging the set starts the break timer automatically."
            )
        }
    }

    private func phaseCard(title: String, subtitle: String, tint: Color, targetText: String?) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(timerValue(at: context.date))
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(tint)
                    }

                    Spacer()

                    if let targetText {
                        Text(targetText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.6))
            )
        }
    }

    private func phaseSummary(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }

    private func timerValue(at date: Date) -> String {
        guard let phaseStartedAt else {
            return intervalLabel(0)
        }

        return intervalLabel(date.timeIntervalSince(phaseStartedAt))
    }

    private func intervalLabel(_ interval: TimeInterval?) -> String {
        guard let interval else { return "None" }
        let totalSeconds = max(Int(interval.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var effortScale: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Effort")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("1 hard • 10 easy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...10, id: \.self) { score in
                        Button {
                            onEffortSelected(score)
                        } label: {
                            Text("\(score)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(lastFeedback?.score == score ? .white : Color.primary)
                                .frame(width: 42, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(lastFeedback?.score == score ? effortColor(for: score) : Color.primary.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("1 = too hard • 10 = too easy")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func effortColor(for score: Int) -> Color {
        switch score {
        case 1...4:
            return AppTheme.warning
        case 8...10:
            return AppTheme.accentWarm
        default:
            return AppTheme.accent
        }
    }
}

private struct BreakTargetSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSeconds: Int

    let onSave: (Int) -> Void

    private let options = Array(stride(from: 30, through: 300, by: 15))

    init(selectedSeconds: Int, onSave: @escaping (Int) -> Void) {
        _selectedSeconds = State(initialValue: BreakTargetSheet.closestOption(to: selectedSeconds))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Custom break target") {
                    Picker("Seconds", selection: $selectedSeconds) {
                        ForEach(options, id: \.self) { option in
                            Text("\(option) sec").tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            }
            .navigationTitle("Break Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(selectedSeconds)
                        dismiss()
                    }
                }
            }
        }
    }

    private static func closestOption(to seconds: Int) -> Int {
        let options = Array(stride(from: 30, through: 300, by: 15))
        return options.min(by: { abs($0 - seconds) < abs($1 - seconds) }) ?? 90
    }
}
