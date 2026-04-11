import SwiftUI

struct ProgressView: View {
    @EnvironmentObject private var store: AppStore

    private var viewModel: ProgressViewModel {
        ProgressViewModel(store: store)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header

                if viewModel.hasCompletedWorkouts {
                    weeklySummaryCard
                    progressSummary
                    trendCard
                    badgesCard
                    recentWinsCard
                } else {
                    weeklySummaryCard
                    EmptyStateView(
                        title: "No workouts logged yet",
                        message: "Complete today’s session to build your first streak and unlock your first progress snapshot.",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.shell.ignoresSafeArea())
    }

    private var weeklySummaryCard: some View {
        HStack(spacing: 12) {
            summaryStat(
                value: "\(viewModel.weeklyWorkoutsCount)",
                label: "Workouts",
                caption: "This week"
            )

            Divider().frame(height: 52)

            summaryStat(
                value: viewModel.weeklyTotalVolumeLabel,
                label: "Volume",
                caption: "This week"
            )

            Divider().frame(height: 52)

            summaryStat(
                value: "\(viewModel.weeklyAverageDurationMinutes) min",
                label: "Avg Duration",
                caption: "Per session"
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func summaryStat(value: String, label: String, caption: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.largeTitle.bold())
            Text("Clear signals, low pressure, and enough detail to show momentum.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var progressSummary: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                ProgressRing(
                    progress: viewModel.weeklyActiveDaysProgress,
                    valueText: "\(viewModel.weeklyActiveDaysCount)/\(viewModel.weeklyGoal)",
                    caption: "Days"
                )
                .frame(width: 110, height: 110)

                ProgressRing(
                    progress: viewModel.weeklyMinutesProgress,
                    valueText: "\(viewModel.weeklyMinutesCompleted)",
                    caption: "Minutes"
                )
                .frame(width: 110, height: 110)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly progress")
                    .font(.headline)
                Text("Active days: \(viewModel.weeklyActiveDaysCount) of \(viewModel.weeklyGoal) planned days this week.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Workout time: \(viewModel.weeklyMinutesCompleted) of \(viewModel.weeklyMinutesGoal) minutes this week.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                StatCard(
                    title: "Current streak",
                    value: "\(viewModel.currentStreak)",
                    subtitle: "Consecutive active days",
                    icon: "flame.fill"
                )
                StatCard(
                    title: "Total workouts",
                    value: "\(viewModel.totalWorkouts)",
                    subtitle: "Completed sessions saved locally",
                    icon: "checkmark.circle.fill"
                )
            }

            if viewModel.personalRecords.isEmpty == false {
                SectionHeader(title: "Personal records", subtitle: "Small wins that are easy to spot in a demo.")

                ForEach(viewModel.personalRecords) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.exerciseName)
                                .font(.headline)
                            Text("\(record.weight) • \(record.reps) reps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(record.achievedOn.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    )
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "Chest press trend", subtitle: "A simple benchmark card instead of a dense chart.")

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(viewModel.trendEntries) { entry in
                    VStack(spacing: 10) {
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.heroGradient)
                                .frame(height: max(CGFloat(entry.value / maxTrendValue) * geometry.size.height, 12))
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                        .frame(height: 110)

                        Text(entry.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var badgesCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "Milestones", subtitle: "Lightweight badges without turning progress into pressure.")

            ForEach(viewModel.badges) { badge in
                HStack(spacing: 14) {
                    Image(systemName: badge.icon)
                        .font(.title3)
                        .foregroundStyle(badge.isUnlocked ? AppTheme.accent : .secondary)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill((badge.isUnlocked ? AppTheme.accent : Color.secondary).opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(badge.title)
                            .font(.headline)
                        Text(badge.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(badge.isUnlocked ? "Unlocked" : "Locked")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(badge.isUnlocked ? AppTheme.success : .secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var recentWinsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent wins", subtitle: "Supportive highlights you can scan in a few seconds.")

            ForEach(viewModel.recentWins, id: \.self) { win in
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppTheme.accentWarm)
                    Text(win)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var maxTrendValue: Double {
        max(viewModel.trendEntries.map(\.value).max() ?? 1, 1)
    }
}

#Preview {
    ProgressView()
        .environmentObject(AppStore.preview)
}
