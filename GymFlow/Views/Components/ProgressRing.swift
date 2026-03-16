import SwiftUI

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 14
    var valueText: String
    var caption: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.accentWarm, AppTheme.accent, AppTheme.success],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)

            VStack(spacing: 4) {
                Text(valueText)
                    .font(.title3.bold())
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue(valueText)
    }
}
