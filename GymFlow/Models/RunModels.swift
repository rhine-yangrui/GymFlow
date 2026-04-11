import Foundation

struct RunRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let totalDistance: Double
    let totalDuration: TimeInterval
    let averagePace: Double
    let calories: Int
    let elevationGain: Double
    let splits: [RunSplit]
    let route: [RoutePoint]

    var distanceInKm: Double { totalDistance / 1000.0 }
    var distanceInMiles: Double { totalDistance / 1609.34 }

    var formattedPace: String {
        let minutes = Int(averagePace) / 60
        let seconds = Int(averagePace) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    var formattedDuration: String {
        let h = Int(totalDuration) / 3600
        let m = (Int(totalDuration) % 3600) / 60
        let s = Int(totalDuration) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    var formattedDistanceKm: String {
        String(format: "%.2f", distanceInKm)
    }
}

struct RunSplit: Identifiable, Codable, Hashable {
    let id: UUID
    let kilometer: Int
    let duration: TimeInterval
    let pace: Double
    let elevationChange: Double

    var formattedPace: String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    var formattedElevationChange: String {
        let rounded = Int(elevationChange.rounded())
        if rounded >= 0 {
            return "+\(rounded)m"
        }
        return "\(rounded)m"
    }
}

struct RoutePoint: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let elevation: Double
    let timestamp: TimeInterval
}

enum RunMode: String, CaseIterable, Identifiable, Codable {
    case freeRun = "Free Run"
    case distanceGoal = "Distance Goal"
    case timeGoal = "Time Goal"
    case intervals = "Intervals"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .freeRun:
            return "figure.run"
        case .distanceGoal:
            return "flag.checkered"
        case .timeGoal:
            return "timer"
        case .intervals:
            return "repeat"
        }
    }

    var shortLabel: String {
        switch self {
        case .freeRun:
            return "Free"
        case .distanceGoal:
            return "Dist"
        case .timeGoal:
            return "Time"
        case .intervals:
            return "Intv"
        }
    }
}

enum RunState: Equatable {
    case idle
    case countdown
    case active
    case paused
    case completed
}
