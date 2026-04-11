import SwiftUI

struct RunSummaryView: View {
    @ObservedObject var viewModel: RunViewModel

    @State private var headerScale: CGFloat = 0.85
    @State private var headerOpacity: Double = 0

    private var record: RunRecord? {
        viewModel.completedRun
    }

    private var fastestSplitID: UUID? {
        guard let record, record.splits.isEmpty == false else { return nil }
        return record.splits.min(by: { $0.pace < $1.pace })?.id
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                celebrationHeader
                if let record {
                    statsGrid(for: record)
                    splitsSection(for: record)
                }
                actionButtons
            }
            .padding(20)
            .padding(.bottom, 32)
        }
        .background(AppTheme.shell.ignoresSafeArea())
        .onAppear {
            FeedbackEngine.success()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                headerScale = 1.0
                headerOpacity = 1.0
            }
        }
    }

    private var celebrationHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                Text("Run Complete")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Nice work. Here is how today's run looked.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.heroGradient)
        )
        .scaleEffect(headerScale)
        .opacity(headerOpacity)
    }

    private func statsGrid(for record: RunRecord) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                summaryStatCard(value: record.formattedDistanceKm, unit: "km", label: "Distance")
                summaryStatCard(value: record.formattedDuration, unit: "time", label: "Duration")
                summaryStatCard(value: record.formattedPace, unit: "/km", label: "Avg pace")
            }
            HStack(spacing: 14) {
                summaryStatCard(value: "\(record.calories)", unit: "cal", label: "Calories")
                summaryStatCard(value: "+\(Int(record.elevationGain))", unit: "m", label: "Elevation")
            }
        }
    }

    private func summaryStatCard(value: String, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(unit)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    @ViewBuilder
    private func splitsSection(for record: RunRecord) -> some View {
        if record.splits.isEmpty == false {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Splits", subtitle: "Per-kilometer pacing with your best split highlighted.")

                VStack(spacing: 0) {
                    splitsHeaderRow
                    ForEach(Array(record.splits.enumerated()), id: \.element.id) { index, split in
                        splitRow(split, avgPace: record.averagePace, isFastest: split.id == fastestSplitID)
                        if index < record.splits.count - 1 {
                            Divider()
                                .padding(.leading, 18)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppTheme.card)
                )
            }
        }
    }

    private var splitsHeaderRow: some View {
        HStack {
            Text("KM")
                .frame(width: 36, alignment: .leading)
            Text("PACE")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("ELEV")
                .frame(width: 60, alignment: .trailing)
        }
        .font(.caption.weight(.bold))
        .tracking(1)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func splitRow(_ split: RunSplit, avgPace: Double, isFastest: Bool) -> some View {
        HStack {
            HStack(spacing: 6) {
                Text("\(split.kilometer)")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                if isFastest {
                    Image(systemName: "bolt.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.accentWarm)
                }
            }
            .frame(width: 36, alignment: .leading)

            Text(split.formattedPace)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(paceColor(for: split.pace, avg: avgPace))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(split.formattedElevationChange)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private func paceColor(for pace: Double, avg: Double) -> Color {
        guard avg > 0 else { return .primary }
        if pace < avg - 3 {
            return AppTheme.success
        } else if pace > avg + 3 {
            return AppTheme.danger
        } else {
            return .primary
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Save Run", systemImage: "tray.and.arrow.down.fill") {
                FeedbackEngine.success()
                viewModel.saveCompletedRun()
            }

            Button {
                FeedbackEngine.impact()
                viewModel.discardCompletedRun()
            } label: {
                Text("Discard")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.danger)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    let vm = RunViewModel()
    vm.completedRun = RunRecord(
        id: UUID(),
        date: Date(),
        totalDistance: 5230,
        totalDuration: 1720,
        averagePace: 329,
        calories: 412,
        elevationGain: 35,
        splits: [
            RunSplit(id: UUID(), kilometer: 1, duration: 335, pace: 335, elevationChange: 8),
            RunSplit(id: UUID(), kilometer: 2, duration: 328, pace: 328, elevationChange: 12),
            RunSplit(id: UUID(), kilometer: 3, duration: 340, pace: 340, elevationChange: -3),
            RunSplit(id: UUID(), kilometer: 4, duration: 322, pace: 322, elevationChange: 10),
            RunSplit(id: UUID(), kilometer: 5, duration: 318, pace: 318, elevationChange: 8)
        ],
        route: []
    )
    return RunSummaryView(viewModel: vm)
}
