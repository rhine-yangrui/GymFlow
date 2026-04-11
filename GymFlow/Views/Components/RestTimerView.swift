import SwiftUI

struct RestTimerView: View {
    var totalSeconds: Int = 90
    var onComplete: () -> Void
    var onDismiss: () -> Void

    @State private var remainingSeconds: Int
    @State private var isFinished: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(totalSeconds: Int = 90, onComplete: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.totalSeconds = totalSeconds
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        self._remainingSeconds = State(initialValue: totalSeconds)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    private var timeLabel: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 22) {
            Text(isFinished ? "Rest Complete" : "Rest Timer")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.15), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppTheme.accent,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                VStack(spacing: 4) {
                    Text(timeLabel)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                    Text(isFinished ? "Ready for next set" : "Tap to skip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            .contentShape(Circle())
            .onTapGesture {
                FeedbackEngine.impact()
                onDismiss()
            }

            Text(isFinished ? "Nice break. Let's go." : "Breathe and reset between sets.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
        .padding(.horizontal, 24)
        .onReceive(timer) { _ in
            guard isFinished == false else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                if remainingSeconds == 0 {
                    isFinished = true
                    FeedbackEngine.success()
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    RestTimerView(totalSeconds: 90, onComplete: {}, onDismiss: {})
        .padding()
        .background(AppTheme.shell)
}
