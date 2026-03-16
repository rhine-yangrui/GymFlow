import SwiftUI

struct RecoveryRecommendationCard: View {
    var recommendation: RecoveryRecommendation

    private var accent: Color {
        switch recommendation {
        case .trainAsPlanned:
            return AppTheme.success
        case .goLighterToday:
            return AppTheme.warning
        case .takeRecoveryDay:
            return AppTheme.accent
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: recommendation.icon)
                .font(.title3)
                .foregroundStyle(accent)

            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.rawValue)
                    .font(.headline)
                Text(recommendation.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
        )
    }
}
