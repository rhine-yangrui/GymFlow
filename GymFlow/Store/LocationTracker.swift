import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationTracker: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var latestLocation: CLLocation?
    @Published var errorMessage: String?
    @Published private(set) var isTracking: Bool = false

    let locationPublisher = PassthroughSubject<CLLocation, Never>()

    private let manager = CLLocationManager()
    private var pendingStart: Bool = false

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func requestAuthorizationIfNeeded() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func startTracking() {
        errorMessage = nil
        switch authorizationStatus {
        case .notDetermined:
            pendingStart = true
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access is disabled. Enable it for GymFlow in Settings to track runs."
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            isTracking = true
        @unknown default:
            break
        }
    }

    func stopTracking() {
        pendingStart = false
        manager.stopUpdatingLocation()
        isTracking = false
    }

    private func ingest(_ locations: [CLLocation]) {
        for location in locations where shouldAccept(location) {
            latestLocation = location
            locationPublisher.send(location)
        }
    }

    private func applyAuthorization(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if pendingStart {
                pendingStart = false
                manager.startUpdatingLocation()
                isTracking = true
                errorMessage = nil
            }
        case .denied, .restricted:
            errorMessage = "Location access is disabled. Enable it for GymFlow in Settings to track runs."
            pendingStart = false
            manager.stopUpdatingLocation()
            isTracking = false
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    private func applyError(_ description: String) {
        errorMessage = "Location error: \(description)"
    }

    private func shouldAccept(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy > 0, location.horizontalAccuracy <= 30 else { return false }
        guard abs(location.timestamp.timeIntervalSinceNow) < 5 else { return false }
        return true
    }
}

extension LocationTracker: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let snapshot = locations
        Task { @MainActor [weak self] in
            self?.ingest(snapshot)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.applyAuthorization(status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let description = error.localizedDescription
        Task { @MainActor [weak self] in
            self?.applyError(description)
        }
    }
}
