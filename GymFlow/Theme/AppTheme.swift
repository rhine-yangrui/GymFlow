import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.19, green: 0.66, blue: 0.58)
    static let accentWarm = Color(red: 0.94, green: 0.61, blue: 0.33)
    static let success = Color(red: 0.28, green: 0.73, blue: 0.48)
    static let warning = Color(red: 0.92, green: 0.71, blue: 0.25)
    static let danger = Color(red: 0.86, green: 0.37, blue: 0.38)
    static let shell = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.38, blue: 0.34),
            Color(red: 0.15, green: 0.55, blue: 0.47),
            Color(red: 0.88, green: 0.55, blue: 0.32)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
