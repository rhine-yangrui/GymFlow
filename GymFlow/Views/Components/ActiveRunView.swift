import SwiftUI

struct ActiveRunView: View {
    @ObservedObject var viewModel: RunViewModel

    @State private var timePulse: Bool = false

    private var isPaused: Bool {
        viewModel.runState == .paused
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 24)
                heroDistance
                Spacer(minLength: 12)
                secondaryMetricsGrid
                Spacer(minLength: 8)
                splitFlash
                Spacer(minLength: 24)
                controlBar
            }
            .padding(.horizontal, 26)
            .padding(.top, 24)
            .padding(.bottom, 32)

            if viewModel.runState == .countdown {
                countdownOverlay
            }
        }
        .foregroundStyle(.white)
        .statusBarHidden()
        .onChange(of: isPaused) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                timePulse = newValue
            }
            if newValue == false {
                timePulse = false
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.selectedMode.icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(viewModel.selectedMode.rawValue.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            if isPaused {
                Label("PAUSED", systemImage: "pause.fill")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.warning)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.warning.opacity(0.15))
                    )
            }
        }
        .overlay(alignment: .center) {
            Text(viewModel.formattedTime)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .opacity(timePulse ? 0.35 : 1.0)
        }
        .frame(height: 56)
    }

    private var heroDistance: some View {
        VStack(spacing: 4) {
            Text(viewModel.formattedDistance)
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("KILOMETERS")
                .font(.caption.weight(.semibold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private var secondaryMetricsGrid: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                metricCell(value: viewModel.formattedCurrentPace, label: "PACE")
                metricCell(value: viewModel.formattedCalories, label: "CAL")
            }
            HStack(spacing: 14) {
                metricCell(value: viewModel.formattedAvgPace, label: "AVG PACE")
                metricCell(value: viewModel.formattedElevation, label: "ELEV")
            }
        }
    }

    private func metricCell(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    @ViewBuilder
    private var splitFlash: some View {
        if let split = viewModel.latestSplitFlash {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.success)
                Text("Split \(split.kilometer): \(split.formattedPace)/km")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .transition(.scale.combined(with: .opacity))
            .id(split.id)
        } else {
            Color.clear.frame(height: 34)
        }
    }

    private var controlBar: some View {
        Group {
            if viewModel.runState == .paused {
                HStack(spacing: 16) {
                    Button {
                        FeedbackEngine.impact()
                        viewModel.resumeRun()
                    } label: {
                        controlCircle(systemImage: "play.fill", tint: AppTheme.accent)
                    }
                    .buttonStyle(.plain)

                    Button {
                        FeedbackEngine.success()
                        viewModel.stopRun()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "stop.fill")
                                .font(.headline)
                            Text("STOP")
                                .font(.headline.weight(.bold))
                                .tracking(1.5)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 64)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.danger)
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    FeedbackEngine.impact()
                    viewModel.pauseRun()
                } label: {
                    controlCircle(systemImage: "pause.fill", tint: AppTheme.accent)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func controlCircle(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 72, height: 72)
            .background(
                Circle().fill(tint)
            )
            .overlay(
                Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
            )
    }

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Get ready")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(viewModel.countdownValue)")
                    .font(.system(size: 160, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
                    .id(viewModel.countdownValue)
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.65), value: viewModel.countdownValue)
        }
    }
}

#Preview {
    ActiveRunView(viewModel: {
        let vm = RunViewModel()
        vm.runState = .active
        vm.elapsedTime = 754
        vm.distance = 3420
        vm.currentPace = 328
        vm.averagePace = 331
        vm.calories = 171
        vm.elevationGain = 24
        return vm
    }())
}
