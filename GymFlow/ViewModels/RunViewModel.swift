import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
final class RunViewModel: ObservableObject {
    @Published var runState: RunState = .idle
    @Published var selectedMode: RunMode = .freeRun

    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var currentPace: Double = 0
    @Published var averagePace: Double = 0
    @Published var currentElevation: Double = 0
    @Published var elevationGain: Double = 0
    @Published var calories: Int = 0
    @Published var currentSplitKm: Int = 1

    @Published var liveSplits: [RunSplit] = []
    @Published var latestSplitFlash: RunSplit? = nil

    @Published var countdownValue: Int = 3

    @Published var distanceGoalKm: Double = 5.0
    @Published var timeGoalMinutes: Double = 30.0

    @Published var runHistory: [RunRecord] = []

    @Published var completedRun: RunRecord? = nil

    @Published var locationErrorMessage: String? = nil
    @Published var isLocationAuthorized: Bool = false
    @Published var hasGPSFix: Bool = false

    private let locationTracker = LocationTracker()
    private var locationCancellable: AnyCancellable?
    private var authCancellable: AnyCancellable?
    private var errorCancellable: AnyCancellable?

    private var tickCancellable: AnyCancellable?
    private var countdownCancellable: AnyCancellable?
    private var flashDismissTask: Task<Void, Never>? = nil
    private var splitStartTime: TimeInterval = 0
    private var splitStartAltitude: Double = 0
    private var paceWindow: [Double] = []

    private var previousLocation: CLLocation?
    private var routePoints: [RoutePoint] = []

    init() {
        loadSampleHistory()
        isLocationAuthorized = locationTracker.isAuthorized

        authCancellable = locationTracker.$authorizationStatus
            .sink { [weak self] status in
                guard let self else { return }
                self.isLocationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
            }

        errorCancellable = locationTracker.$errorMessage
            .sink { [weak self] message in
                self?.locationErrorMessage = message
            }

        locationCancellable = locationTracker.locationPublisher
            .sink { [weak self] location in
                self?.ingest(location: location)
            }

        locationTracker.requestAuthorizationIfNeeded()
    }

    // MARK: - Run Controls

    func startRun() {
        guard runState == .idle else { return }
        runState = .countdown
        countdownValue = 3

        countdownCancellable?.cancel()
        countdownCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleCountdownTick()
            }
    }

    private func handleCountdownTick() {
        countdownValue -= 1
        if countdownValue <= 0 {
            countdownCancellable?.cancel()
            countdownCancellable = nil
            beginActiveRun()
        }
    }

    private func beginActiveRun() {
        runState = .active
        elapsedTime = 0
        distance = 0
        currentPace = 0
        averagePace = 0
        currentElevation = 0
        elevationGain = 0
        calories = 0
        currentSplitKm = 1
        liveSplits = []
        latestSplitFlash = nil
        splitStartTime = 0
        splitStartAltitude = 0
        paceWindow = []
        previousLocation = nil
        routePoints = []
        hasGPSFix = false
        locationErrorMessage = nil

        locationTracker.startTracking()
        startTickingTimer()
    }

    private func startTickingTimer() {
        tickCancellable?.cancel()
        tickCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleClockTick()
            }
    }

    private func handleClockTick() {
        guard runState == .active else { return }
        elapsedTime += 1

        if distance > 0 {
            averagePace = elapsedTime / (distance / 1000.0)
        }
        calories = Int(distance / 20.0)

        if selectedMode == .distanceGoal, distance >= distanceGoalKm * 1000 {
            stopRun()
        } else if selectedMode == .timeGoal, elapsedTime >= timeGoalMinutes * 60 {
            stopRun()
        }
    }

    func pauseRun() {
        guard runState == .active else { return }
        runState = .paused
        tickCancellable?.cancel()
        tickCancellable = nil
        locationTracker.stopTracking()
    }

    func resumeRun() {
        guard runState == .paused else { return }
        runState = .active
        previousLocation = nil
        paceWindow.removeAll()
        locationTracker.startTracking()
        startTickingTimer()
    }

    func stopRun() {
        tickCancellable?.cancel()
        tickCancellable = nil
        countdownCancellable?.cancel()
        countdownCancellable = nil
        locationTracker.stopTracking()
        runState = .completed
        completedRun = buildRecord()
    }

    func resetRun() {
        tickCancellable?.cancel()
        countdownCancellable?.cancel()
        flashDismissTask?.cancel()
        tickCancellable = nil
        countdownCancellable = nil
        locationTracker.stopTracking()
        runState = .idle
        elapsedTime = 0
        distance = 0
        currentPace = 0
        averagePace = 0
        currentElevation = 0
        elevationGain = 0
        calories = 0
        currentSplitKm = 1
        liveSplits = []
        latestSplitFlash = nil
        paceWindow = []
        previousLocation = nil
        routePoints = []
        countdownValue = 3
        completedRun = nil
        hasGPSFix = false
    }

    // MARK: - Save / Discard

    func saveCompletedRun() {
        if let completedRun {
            runHistory.insert(completedRun, at: 0)
        }
        resetRun()
    }

    func discardCompletedRun() {
        resetRun()
    }

    func deleteRun(_ run: RunRecord) {
        runHistory.removeAll { $0.id == run.id }
    }

    // MARK: - Sensor ingestion

    private func ingest(location: CLLocation) {
        guard runState == .active else { return }

        hasGPSFix = true

        if let previous = previousLocation {
            let altitudeDelta = location.altitude - previous.altitude
            if altitudeDelta > 0.5 {
                elevationGain += altitudeDelta
            }

            let distanceDelta = location.distance(from: previous)
            if distanceDelta >= 1.0 && distanceDelta < 120 {
                distance += distanceDelta
            }
        } else {
            splitStartAltitude = location.altitude
        }
        currentElevation = location.altitude
        previousLocation = location

        let speed = location.speed
        if location.speedAccuracy >= 0 && speed > 0.5 {
            let paceSecPerKm = 1000.0 / speed
            paceWindow.append(paceSecPerKm)
            if paceWindow.count > 5 {
                paceWindow.removeFirst(paceWindow.count - 5)
            }
            currentPace = paceWindow.reduce(0, +) / Double(paceWindow.count)
        } else if speed <= 0.3 {
            paceWindow.removeAll()
            currentPace = 0
        }

        routePoints.append(
            RoutePoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                elevation: location.altitude,
                timestamp: location.timestamp.timeIntervalSince1970
            )
        )

        let reachedKm = Int(distance / 1000.0) + 1
        if reachedKm > currentSplitKm {
            let splitDuration = elapsedTime - splitStartTime
            let split = RunSplit(
                id: UUID(),
                kilometer: currentSplitKm,
                duration: splitDuration,
                pace: splitDuration,
                elevationChange: location.altitude - splitStartAltitude
            )
            liveSplits.append(split)
            flashSplit(split)
            splitStartTime = elapsedTime
            splitStartAltitude = location.altitude
            currentSplitKm = reachedKm
            FeedbackEngine.success()
        }
    }

    private func flashSplit(_ split: RunSplit) {
        latestSplitFlash = split
        flashDismissTask?.cancel()
        flashDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard let self, !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                self.latestSplitFlash = nil
            }
        }
    }

    private func buildRecord() -> RunRecord {
        let splits = liveSplits.isEmpty ? syntheticSplitsIfNeeded() : liveSplits
        let avgPace: Double
        if distance > 0 {
            avgPace = elapsedTime / (distance / 1000.0)
        } else {
            avgPace = 0
        }
        return RunRecord(
            id: UUID(),
            date: Date(),
            totalDistance: distance,
            totalDuration: elapsedTime,
            averagePace: avgPace,
            calories: calories,
            elevationGain: elevationGain,
            splits: splits,
            route: routePoints
        )
    }

    private func syntheticSplitsIfNeeded() -> [RunSplit] {
        guard distance > 0, elapsedTime > 0 else { return [] }
        let fullKm = Int(distance / 1000.0)
        guard fullKm >= 1 else { return [] }
        let perKm = elapsedTime / Double(fullKm)
        return (1...fullKm).map { km in
            RunSplit(
                id: UUID(),
                kilometer: km,
                duration: perKm,
                pace: perKm,
                elevationChange: 0
            )
        }
    }

    // MARK: - Formatted Strings

    var formattedTime: String {
        let h = Int(elapsedTime) / 3600
        let m = (Int(elapsedTime) % 3600) / 60
        let s = Int(elapsedTime) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    var formattedDistance: String {
        String(format: "%.2f", distance / 1000.0)
    }

    var formattedCurrentPace: String {
        guard currentPace > 0 && currentPace < 1000 else { return "--'--\"" }
        let m = Int(currentPace) / 60
        let s = Int(currentPace) % 60
        return String(format: "%d'%02d\"", m, s)
    }

    var formattedAvgPace: String {
        guard averagePace > 0 && averagePace < 1000 else { return "--'--\"" }
        let m = Int(averagePace) / 60
        let s = Int(averagePace) % 60
        return String(format: "%d'%02d\"", m, s)
    }

    var formattedElevation: String {
        String(format: "+%.0fm", elevationGain)
    }

    var formattedCalories: String {
        "\(calories)"
    }

    // MARK: - Sample data

    private func loadSampleHistory() {
        runHistory = [
            RunRecord(
                id: UUID(),
                date: Date().addingTimeInterval(-86400),
                totalDistance: 5230,
                totalDuration: 1720,
                averagePace: 329,
                calories: 412,
                elevationGain: 35,
                splits: [
                    RunSplit(id: UUID(), kilometer: 1, duration: 335, pace: 335, elevationChange: 8),
                    RunSplit(id: UUID(), kilometer: 2, duration: 328, pace: 328, elevationChange: 12),
                    RunSplit(id: UUID(), kilometer: 3, duration: 340, pace: 340, elevationChange: -3),
                    RunSplit(id: UUID(), kilometer: 4, duration: 322, pace: 322, elevationChange: 10),
                    RunSplit(id: UUID(), kilometer: 5, duration: 318, pace: 318, elevationChange: 8),
                ],
                route: []
            ),
            RunRecord(
                id: UUID(),
                date: Date().addingTimeInterval(-259200),
                totalDistance: 3120,
                totalDuration: 1080,
                averagePace: 346,
                calories: 248,
                elevationGain: 18,
                splits: [
                    RunSplit(id: UUID(), kilometer: 1, duration: 352, pace: 352, elevationChange: 5),
                    RunSplit(id: UUID(), kilometer: 2, duration: 348, pace: 348, elevationChange: 8),
                    RunSplit(id: UUID(), kilometer: 3, duration: 338, pace: 338, elevationChange: 5),
                ],
                route: []
            ),
            RunRecord(
                id: UUID(),
                date: Date().addingTimeInterval(-604800),
                totalDistance: 10050,
                totalDuration: 3240,
                averagePace: 322,
                calories: 780,
                elevationGain: 85,
                splits: (1...10).map { km in
                    RunSplit(
                        id: UUID(),
                        kilometer: km,
                        duration: Double.random(in: 310...340),
                        pace: Double.random(in: 310...340),
                        elevationChange: Double.random(in: -5...12)
                    )
                },
                route: []
            )
        ]
    }
}
