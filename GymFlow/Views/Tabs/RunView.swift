import SwiftUI

struct RunView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var viewModel = RunViewModel()
    @State private var expandedRunID: UUID? = nil
    @State private var pendingDeletion: RunRecord? = nil

    var body: some View {
        ZStack {
            switch viewModel.runState {
            case .idle:
                idleScreen
            case .countdown, .active, .paused:
                ActiveRunView(viewModel: viewModel)
                    .transition(.opacity)
            case .completed:
                RunSummaryView(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.runState)
        .onAppear { viewModel.store = store }
    }

    // MARK: - Idle screen

    private var idleScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                startRunButton
                modeSelector
                goalControls
                recentRunsSection
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.shell.ignoresSafeArea())
        .confirmationDialog(
            "Delete run?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if $0 == false { pendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let pendingDeletion {
                    FeedbackEngine.impact()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.deleteRunRecord(pendingDeletion.id)
                    }
                }
                pendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            Text("This removes the saved run from your history.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Run")
                .font(.largeTitle.bold())
            Text("Pick a mode, tap start, and let the pace guide the run.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var startRunButton: some View {
        Button {
            FeedbackEngine.impact()
            viewModel.startRun()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                Text("START")
                    .font(.headline.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.white)
                Text("RUN")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: 148, height: 148)
            .background(
                Circle().fill(AppTheme.heroGradient)
            )
            .overlay(
                Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 3)
            )
            .shadow(color: AppTheme.accent.opacity(0.35), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var modeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RunMode.allCases) { mode in
                    modeChip(for: mode)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func modeChip(for mode: RunMode) -> some View {
        let isSelected = viewModel.selectedMode == mode
        return Button {
            FeedbackEngine.impact()
            viewModel.selectedMode = mode
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.caption.weight(.semibold))
                Text(mode.rawValue)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.card))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var goalControls: some View {
        switch viewModel.selectedMode {
        case .distanceGoal:
            goalCard(
                title: "Distance goal",
                value: String(format: "%.1f km", viewModel.distanceGoalKm),
                range: 1...20,
                step: 0.5,
                binding: $viewModel.distanceGoalKm
            )
        case .timeGoal:
            goalCard(
                title: "Time goal",
                value: "\(Int(viewModel.timeGoalMinutes)) min",
                range: 5...120,
                step: 5,
                binding: $viewModel.timeGoalMinutes
            )
        case .freeRun, .intervals:
            EmptyView()
        }
    }

    private func goalCard(title: String, value: String, range: ClosedRange<Double>, step: Double, binding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .monospacedDigit()
            }

            Slider(value: binding, in: range, step: step)
                .tint(AppTheme.accent)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recent runs", subtitle: "Tap a run to see its splits.")

            if store.runHistory.isEmpty {
                EmptyStateView(
                    title: "No runs yet",
                    message: "Tap Start Run to log your first session.",
                    icon: "figure.run"
                )
            } else {
                ForEach(store.runHistory) { run in
                    runHistoryCard(run)
                }
            }
        }
    }

    private func runHistoryCard(_ run: RunRecord) -> some View {
        let isExpanded = expandedRunID == run.id
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                FeedbackEngine.impact()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    expandedRunID = isExpanded ? nil : run.id
                }
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.accent)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(relativeDateLabel(for: run.date))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\(run.formattedDistanceKm) km")
                            .font(.title3.bold())
                        HStack(spacing: 12) {
                            Label(run.formattedDuration, systemImage: "clock")
                            Label("\(run.formattedPace)/km", systemImage: "speedometer")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedRunContent(run)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05))
        )
    }

    @ViewBuilder
    private func expandedRunContent(_ run: RunRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack(spacing: 20) {
                miniStat(value: "\(run.calories)", label: "cal")
                miniStat(value: "+\(Int(run.elevationGain))m", label: "elev")
                miniStat(value: "\(run.splits.count)", label: "splits")
                Spacer()
            }

            if run.splits.isEmpty == false {
                ForEach(run.splits) { split in
                    HStack {
                        Text("KM \(split.kilometer)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .leading)
                        Text(split.formattedPace)
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                        Spacer()
                        Text(split.formattedElevationChange)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 4)
                }
            }

            Button {
                pendingDeletion = run
            } label: {
                Label("Delete run", systemImage: "trash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.danger.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func relativeDateLabel(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date()).capitalized
    }
}

#Preview {
    RunView()
        .environmentObject(AppStore.preview)
}
