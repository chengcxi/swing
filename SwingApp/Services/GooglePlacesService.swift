import Foundation
import CoreLocation
import GooglePlacesSwift

enum GooglePlacesError: Error {
    case apiError(String)
}

class GooglePlacesService {
    static let shared = GooglePlacesService()

    // Default location bias — UCSB area, same fallback Cheng used in CourseViewModel
    private let defaultCoordinate = CLLocationCoordinate2D(latitude: 34.4140, longitude: -119.8489)

    private init() {}

    func searchGolfCourses(query: String) async throws -> [Course] {
        let searchQuery = query.isEmpty ? "golf course" : "\(query) golf course"

        let region = CircularCoordinateRegion(center: defaultCoordinate, radius: 200_000)
        let request = SearchByTextRequest(
            textQuery: searchQuery,
            placeProperties: [.placeID, .displayName, .formattedAddress, .coordinate],
            locationBias: region,
            maxResultCount: 20
        )

        switch await PlacesClient.shared.searchByText(with: request) {
        case .success(let places):
            return places.map { place in
                let (city, state) = parseCityState(from: place.formattedAddress)
                return Course(
                    id: UUID(),
                    name: place.displayName ?? place.formattedAddress ?? "Unknown Course",
                    location: place.formattedAddress ?? "Unknown Location",
                    latitude: place.location.latitude,
                    longitude: place.location.longitude,
                    googlePlaceId: place.placeID,
                    city: city,
                    state: state
                )
            }
        case .failure(let error):
            throw GooglePlacesError.apiError(error.localizedDescription)
        }
    }

    private func parseCityState(from address: String?) -> (city: String?, state: String?) {
        guard let address = address else { return (nil, nil) }
        let parts = address.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 3 else { return (parts.first, nil) }
        let city = parts[parts.count - 3]
        let stateZip = parts[parts.count - 2]
        let state = stateZip.components(separatedBy: " ").first
        return (city, state)
    }
}
