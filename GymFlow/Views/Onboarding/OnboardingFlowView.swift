import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            AppTheme.heroGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    content

                    VStack(spacing: 12) {
                        if viewModel.currentStep > 0 {
                            Button("Back", action: viewModel.goBack)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.92))
                        }

                        PrimaryButton(title: primaryActionTitle, systemImage: "arrow.right") {
                            handlePrimaryAction()
                        }
                        .disabled(viewModel.canContinue == false)
                        .opacity(viewModel.canContinue ? 1 : 0.45)
                    }
                }
                .padding(24)
                .padding(.top, 18)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index < viewModel.progressStep ? Color.white : Color.white.opacity(0.28))
                        .frame(height: 8)
                }
            }

            Text("GymFlow")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            Text(stepTitle)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text(stepSubtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.currentStep {
        case 0:
            optionCardList(
                options: FitnessGoal.allCases,
                selected: viewModel.selectedGoal,
                title: { $0.rawValue },
                subtitle: { $0.summary },
                icon: { $0.icon },
                onSelect: { viewModel.selectedGoal = $0 }
            )
        case 1:
            optionCardList(
                options: TrainingFrequency.allCases,
                selected: viewModel.selectedFrequency,
                title: { $0.rawValue },
                subtitle: { $0.summary },
                icon: { _ in "calendar" },
                onSelect: { viewModel.selectedFrequency = $0 }
            )
        case 2:
            optionCardList(
                options: WorkoutLocation.allCases,
                selected: viewModel.selectedLocation,
                title: { $0.rawValue },
                subtitle: { $0.summary },
                icon: {
                    switch $0 {
                    case .gym:
                        return "dumbbell.fill"
                    case .home:
                        return "house.fill"
                    case .both:
                        return "arrow.triangle.2.circlepath"
                    }
                },
                onSelect: { viewModel.selectedLocation = $0 }
            )
        case 3:
            optionCardList(
                options: ExperienceLevel.allCases,
                selected: viewModel.selectedExperience,
                title: { $0.rawValue },
                subtitle: { $0.summary },
                icon: { _ in "chart.line.uptrend.xyaxis" },
                onSelect: { viewModel.selectedExperience = $0 }
            )
        default:
            summaryStep
        }
    }

    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your plan is ready")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("You’ll land on a clear Today screen, a simple weekly plan, progress snapshots, and a built-in recovery check.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }

            VStack(spacing: 14) {
                summaryRow(title: "Goal", value: viewModel.selectedGoal?.rawValue ?? "")
                summaryRow(title: "Frequency", value: viewModel.selectedFrequency?.rawValue ?? "")
                summaryRow(title: "Location", value: viewModel.selectedLocation?.rawValue ?? "")
                summaryRow(title: "Experience", value: viewModel.selectedExperience?.rawValue ?? "")
            }

            if let firstWorkout = viewModel.previewPlan?.days.first(where: { $0.isRecovery == false }) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("First workout")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(firstWorkout.title) • \(firstWorkout.focusArea)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(firstWorkout.exercises.count) exercises")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.14))
                )
            }
        }
    }

    private var primaryActionTitle: String {
        viewModel.currentStep == viewModel.totalSteps - 1 ? "Start with My Plan" : "Continue"
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case 0:
            return "What do you want from training?"
        case 1:
            return "How often feels realistic?"
        case 2:
            return "Where will you usually train?"
        case 3:
            return "What best describes you?"
        default:
            return "You’re set"
        }
    }

    private var stepSubtitle: String {
        switch viewModel.currentStep {
        case 0:
            return "Pick the outcome that would feel most valuable this semester."
        case 1:
            return "Choose the schedule you can actually keep, not the perfect one."
        case 2:
            return "We’ll make swaps easy when campus life gets messy."
        case 3:
            return "This helps keep the plan challenging without feeling punishing."
        default:
            return "GymFlow built a simple plan that keeps your next step obvious."
        }
    }

    private func handlePrimaryAction() {
        if viewModel.currentStep == viewModel.totalSteps - 1 {
            guard let profile = viewModel.profile else { return }
            FeedbackEngine.success()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                store.completeOnboarding(with: profile)
            }
        } else {
            FeedbackEngine.impact()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                viewModel.advance()
            }
        }
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.14))
        )
    }

    private func optionCardList<Option: Identifiable & Equatable>(
        options: [Option],
        selected: Option?,
        title: @escaping (Option) -> String,
        subtitle: @escaping (Option) -> String,
        icon: @escaping (Option) -> String,
        onSelect: @escaping (Option) -> Void
    ) -> some View {
        VStack(spacing: 14) {
            ForEach(options) { option in
                Button {
                    FeedbackEngine.impact()
                    onSelect(option)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: icon(option))
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.14))
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(title(option))
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(subtitle(option))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: selected == option ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(selected == option ? Color.white.opacity(0.20) : Color.white.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(selected == option ? 0.42 : 0.18), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppStore())
}
