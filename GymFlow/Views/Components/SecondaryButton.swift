import SwiftUI

struct SecondaryButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}
