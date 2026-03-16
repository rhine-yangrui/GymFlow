import Foundation

struct Badge: Identifiable, Equatable {
    let id: String
    var title: String
    var subtitle: String
    var icon: String
    var isUnlocked: Bool
}

struct PersonalRecord: Identifiable, Equatable {
    let id: String
    var exerciseName: String
    var weight: String
    var reps: Int
    var achievedOn: Date
}

struct TrendEntry: Identifiable, Equatable {
    let id = UUID()
    var label: String
    var value: Double
}
