import SwiftUI

struct ExerciseCard: View {
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
    var onStartBreak: () -> Void
    var onEndBreak: () -> Void
    var onBreakTargetSelected: (Int) -> Void
    var onTooEasy: () -> Void
    var onTooHard: () -> Void
    var onEdit: () -> Void

    private let breakOptions = [45, 60, 90, 120]

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
        default:
            return "Start Set \(nextSetNumber) of \(exercise.targetSets)"
        }
    }

    private var breakTitle: String {
        liveStatus == .breakTime ? "End Break" : "Break"
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

            HStack(spacing: 12) {
                feedbackButton(title: "Too Easy", icon: "arrow.up.circle", tint: AppTheme.accentWarm, action: onTooEasy)
                feedbackButton(title: "Too Hard", icon: "arrow.down.circle", tint: AppTheme.warning, action: onTooHard)
            }

            Button(action: {
                if liveStatus == .breakTime {
                    onEndBreak()
                } else {
                    onStartBreak()
                }
            }) {
                Label(breakTitle, systemImage: liveStatus == .breakTime ? "pause.circle.fill" : "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .disabled(liveStatus == .training)
            .opacity(liveStatus == .training ? 0.45 : 1)

            if let lastFeedback {
                Label("Last adjustment: \(lastFeedback.rawValue)", systemImage: "slider.horizontal.3")
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
                    Text("Break target")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

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
                subtitle: "The set timer starts as soon as you begin the set.",
                tint: AppTheme.accentWarm,
                targetText: nil
            )
        case .breakTime:
            phaseCard(
                title: "Break timer",
                subtitle: "Use the preset target or end the break whenever you are ready.",
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
                subtitle: "Tap Start Set when you begin, then log the set when it is done."
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

    private func feedbackButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}
