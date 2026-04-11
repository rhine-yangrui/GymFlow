import SwiftUI

struct PaceRingView: View {
    var currentPace: Double
    var targetPace: Double
    var paceLabel: String
    var lineWidth: CGFloat = 12

    private var progress: Double {
        guard currentPace > 0, targetPace > 0 else { return 0 }
        let ratio = targetPace / currentPace
        return min(max(ratio, 0), 1.2)
    }

    private var ringColor: Color {
        guard currentPace > 0 else { return AppTheme.accent.opacity(0.4) }
        let delta = currentPace - targetPace
        if delta <= 10 {
            return AppTheme.success
        } else if delta <= 35 {
            return AppTheme.warning
        } else {
            return AppTheme.danger
        }
    }

    private var statusLabel: String {
        guard currentPace > 0 else { return "Warming up" }
        let delta = currentPace - targetPace
        if delta <= 10 {
            return "On pace"
        } else if delta <= 35 {
            return "A bit slow"
        } else {
            return "Slower"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
                .animation(.easeInOut(duration: 0.4), value: ringColor)

            VStack(spacing: 2) {
                Text(paceLabel)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("/km")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                Text(statusLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ringColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current pace")
        .accessibilityValue("\(paceLabel) per kilometer, \(statusLabel)")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PaceRingView(currentPace: 330, targetPace: 330, paceLabel: "5'30\"")
            .frame(width: 120, height: 120)
    }
}
