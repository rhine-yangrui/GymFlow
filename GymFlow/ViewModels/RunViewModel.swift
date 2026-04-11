import Foundation
import SwiftUI
import Combine

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

    private var tickCancellable: AnyCancellable?
    private var countdownCancellable: AnyCancellable?
    private var flashDismissTask: Task<Void, Never>? = nil
    private var splitStartTime: TimeInterval = 0
    private var paceHistory: [Double] = []

    init() {
        loadSampleHistory()
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
        paceHistory = []
        startTickingTimer()
    }

    private func startTickingTimer() {
        tickCancellable?.cancel()
        tickCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateSimulatedRun()
            }
    }

    func pauseRun() {
        guard runState == .active else { return }
        runState = .paused
        tickCancellable?.cancel()
        tickCancellable = nil
    }

    func resumeRun() {
        guard runState == .paused else { return }
        runState = .active
        startTickingTimer()
    }

    func stopRun() {
        tickCancellable?.cancel()
        tickCancellable = nil
        countdownCancellable?.cancel()
        countdownCancellable = nil
        runState = .completed
        completedRun = buildRecord()
    }

    func resetRun() {
        tickCancellable?.cancel()
        countdownCancellable?.cancel()
        flashDismissTask?.cancel()
        tickCancellable = nil
        countdownCancellable = nil
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
        paceHistory = []
        countdownValue = 3
        completedRun = nil
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

    // MARK: - Simulation

    private func updateSimulatedRun() {
        elapsedTime += 1

        let baseSpeed = 3.03
        let variance = Double.random(in: -0.3...0.3)
        let speed = max(0.5, baseSpeed + variance)
        distance += speed

        let elevChange = Double.random(in: -0.2...0.3)
        currentElevation += elevChange
        if elevChange > 0 { elevationGain += elevChange }

        if distance > 0 {
            averagePace = elapsedTime / (distance / 1000.0)
            let jitter = Double.random(in: -20...20)
            let rawPace = max(200, min(600, averagePace + jitter))
            paceHistory.append(rawPace)
            if paceHistory.count > 10 {
                paceHistory.removeFirst(paceHistory.count - 10)
            }
            currentPace = paceHistory.reduce(0, +) / Double(paceHistory.count)
        }

        calories = Int(distance / 20.0)

        let reachedKm = Int(distance / 1000.0) + 1
        if reachedKm > currentSplitKm {
            let splitDuration = elapsedTime - splitStartTime
            let split = RunSplit(
                id: UUID(),
                kilometer: currentSplitKm,
                duration: splitDuration,
                pace: splitDuration,
                elevationChange: Double.random(in: -5...10)
            )
            liveSplits.append(split)
            flashSplit(split)
            splitStartTime = elapsedTime
            currentSplitKm = reachedKm
            FeedbackEngine.success()
        }

        if selectedMode == .distanceGoal, distance >= distanceGoalKm * 1000 {
            stopRun()
        } else if selectedMode == .timeGoal, elapsedTime >= timeGoalMinutes * 60 {
            stopRun()
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
            route: []
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
                elevationChange: Double.random(in: -4...10)
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
