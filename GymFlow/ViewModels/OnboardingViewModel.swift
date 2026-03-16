import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var selectedGoal: FitnessGoal?
    @Published var selectedFrequency: TrainingFrequency?
    @Published var selectedLocation: WorkoutLocation?
    @Published var selectedExperience: ExperienceLevel?

    let totalSteps = 5

    var canContinue: Bool {
        switch currentStep {
        case 0:
            return selectedGoal != nil
        case 1:
            return selectedFrequency != nil
        case 2:
            return selectedLocation != nil
        case 3:
            return selectedExperience != nil
        default:
            return profile != nil
        }
    }

    var progressStep: Int {
        min(currentStep + 1, 4)
    }

    var profile: UserProfile? {
        guard let selectedGoal,
              let selectedFrequency,
              let selectedLocation,
              let selectedExperience else {
            return nil
        }

        return UserProfile(
            goal: selectedGoal,
            frequency: selectedFrequency,
            location: selectedLocation,
            experienceLevel: selectedExperience
        )
    }

    var previewPlan: WorkoutPlan? {
        guard let profile else { return nil }
        return WorkoutPlanGenerator.makePlan(for: profile)
    }

    func advance() {
        guard currentStep < totalSteps - 1 else { return }
        currentStep += 1
    }

    func goBack() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }
}
