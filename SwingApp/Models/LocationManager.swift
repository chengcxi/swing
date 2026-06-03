import Foundation
import CoreLocation

@MainActor
final class LocationManager: NSObject, ObservableObject {
  @Published var location: CLLocationCoordinate2D?
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

  private let manager = CLLocationManager()
  private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    authorizationStatus = manager.authorizationStatus
  }

  /// Request permission + get one location fix. Returns immediately if we already have one.
  func requestLocation() async throws -> CLLocationCoordinate2D {
    if let existing = location { return existing }

    return try await withCheckedThrowingContinuation { continuation in
      self.locationContinuation = continuation

      switch manager.authorizationStatus {
      case .notDetermined:
        manager.requestWhenInUseAuthorization()
        // Delegate will call requestLocation() once authorized
      case .authorizedWhenInUse, .authorizedAlways:
        manager.requestLocation()
      case .denied, .restricted:
        continuation.resume(throwing: LocationError.denied)
        self.locationContinuation = nil
      @unknown default:
        continuation.resume(throwing: LocationError.unknown)
        self.locationContinuation = nil
      }
    }
  }

  enum LocationError: Error {
    case denied
    case unknown
  }
}

extension LocationManager: CLLocationManagerDelegate {
  nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    Task { @MainActor in
      self.authorizationStatus = status
      if status == .authorizedWhenInUse || status == .authorizedAlways {
        manager.requestLocation()
      } else if status == .denied || status == .restricted {
        self.locationContinuation?.resume(throwing: LocationError.denied)
        self.locationContinuation = nil
      }
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let coord = locations.last?.coordinate else { return }
    Task { @MainActor in
      self.location = coord
      self.locationContinuation?.resume(returning: coord)
      self.locationContinuation = nil
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    Task { @MainActor in
      self.locationContinuation?.resume(throwing: error)
      self.locationContinuation = nil
    }
  }
}
