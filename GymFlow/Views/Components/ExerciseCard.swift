import SwiftUI

struct ExerciseCard: View {
    var exercise: Exercise
    var completedSets: Int
    var currentWeight: String
    var lastFeedback: EffortFeedback?
    var adjustmentNote: String?
    var onLogSet: () -> Void
    var onTooEasy: () -> Void
    var onTooHard: () -> Void

    private var isComplete: Bool {
        completedSets >= exercise.targetSets
    }

    private var buttonTitle: String {
        completedSets == 0 ? "Log First Set" : "Log Set \(min(completedSets + 1, exercise.targetSets)) of \(exercise.targetSets)"
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

            Text(adjustmentNote ?? exercise.hint)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            PrimaryButton(title: buttonTitle, systemImage: "plus.circle.fill", action: onLogSet)
                .disabled(isComplete)
                .opacity(isComplete ? 0.45 : 1)

            HStack(spacing: 12) {
                feedbackButton(title: "Too Easy", icon: "arrow.up.circle", tint: AppTheme.accentWarm, action: onTooEasy)
                feedbackButton(title: "Too Hard", icon: "arrow.down.circle", tint: AppTheme.warning, action: onTooHard)
            }

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
