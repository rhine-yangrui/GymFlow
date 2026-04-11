import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var energy: RecoveryRating = .medium
    @State private var soreness: RecoveryRating = .medium
    @State private var sleep: RecoveryRating = .medium

    private var viewModel: RecoveryViewModel {
        RecoveryViewModel(store: store)
    }

    private var liveRecommendation: RecoveryRecommendation {
        RecoveryRecommendation.makeRecommendation(energy: energy, soreness: soreness, sleep: sleep)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                recoveryScoreCard
                RecoveryRecommendationCard(recommendation: liveRecommendation)
                checkInCard
                tipsCard
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.shell.ignoresSafeArea())
        .onAppear(perform: loadExistingCheckIn)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery")
                .font(.largeTitle.bold())
            Text("Supportive guidance that keeps recovery and safety part of the plan.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var recoveryScoreCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(viewModel.recoveryStatusColor.opacity(0.15), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: Double(viewModel.recoveryScore) / 100)
                    .stroke(
                        viewModel.recoveryStatusColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(viewModel.recoveryScore)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text("/100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 6) {
                Text("Recovery Score")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(viewModel.recoveryStatusLabel)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(viewModel.lastWorkoutLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var checkInCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "Daily check-in", subtitle: "A lighter day can support long-term consistency.")

            ratingPicker(title: "Energy level", selection: $energy)
            ratingPicker(title: "Soreness", selection: $soreness)
            ratingPicker(title: "Sleep quality", selection: $sleep)

            if let latestCheckIn = viewModel.latestCheckIn {
                Text("Saved for today: \(latestCheckIn.recommendation.rawValue)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            PrimaryButton(title: "Save Recovery Check-In", systemImage: "heart.fill") {
                FeedbackEngine.success()
                store.saveRecoveryCheckIn(energy: energy, soreness: soreness, sleep: sleep)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recovery tips", subtitle: "Beginner-safe reminders that keep the tone calm and useful.")

            ForEach(viewModel.tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(AppTheme.accent)
                    Text(tip)
                        .font(.subheadline)
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func ratingPicker(title: String, selection: Binding<RecoveryRating>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            Picker(title, selection: selection) {
                ForEach(RecoveryRating.allCases) { rating in
                    Text(rating.title).tag(rating)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func loadExistingCheckIn() {
        guard let latestCheckIn = viewModel.latestCheckIn else { return }
        energy = latestCheckIn.energyLevel
        soreness = latestCheckIn.soreness
        sleep = latestCheckIn.sleepQuality
    }
}

#Preview {
    RecoveryView()
        .environmentObject(AppStore.preview)
}
