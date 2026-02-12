import Foundation
import GoogleMaps
import GooglePlaces
import CoreLocation

class GoogleMapsService {
    static let shared = GoogleMapsService()
    private let placesClient = GMSPlacesClient.shared()
    
    // MARK: - Search Golf Courses
    
    func searchGolfCourses(
        query: String,
        near location: CLLocationCoordinate2D?
    ) async throws -> [GMSAutocompletePrediction] {
        return try await withCheckedThrowingContinuation { continuation in
            let filter = GMSAutocompleteFilter()
            filter.types = ["establishment"]
            
            if let location = location {
                filter.locationBias = GMSPlaceRectangularLocationOption(
                    CLLocationCoordinate2D(
                        latitude: location.latitude - 0.5,
                        longitude: location.longitude - 0.5
                    ),
                    CLLocationCoordinate2D(
                        latitude: location.latitude + 0.5,
                        longitude: location.longitude + 0.5
                    )
                )
            }
            
            let token = GMSAutocompleteSessionToken()
            
            placesClient.findAutocompletePredictions(
                fromQuery: query.isEmpty ? "golf course" : "\(query) golf",
                filter: filter,
                sessionToken: token
            ) { results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: results ?? [])
            }
        }
    }
    
    // MARK: - Get Place Details
    
    func getPlaceDetails(placeId: String) async throws -> GMSPlace {
        return try await withCheckedThrowingContinuation { continuation in
            let fields: GMSPlaceField = [
                .name,
                .formattedAddress,
                .coordinate,
                .phoneNumber,
                .website,
                .rating,
                .placeID,
                .addressComponents
            ]
            
            placesClient.fetchPlace(
                fromPlaceID: placeId,
                placeFields: fields,
                sessionToken: nil
            ) { place, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let place = place else {
                    continuation.resume(throwing: GoogleMapsError.placeNotFound)
                    return
                }
                
                continuation.resume(returning: place)
            }
        }
    }
    
    // MARK: - Convert to Golf Course
    
    func convertToGolfCourseInsert(_ place: GMSPlace) -> GolfCourseInsert? {
        guard let name = place.name,
              let address = place.formattedAddress,
              let placeId = place.placeID else {
            return nil
        }
        
        let components = parseAddressComponents(place.addressComponents)
        
        return GolfCourseInsert(
            name: name,
            address: address,
            city: components.city,
            state: components.state,
            country: components.country,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            holes: 18,
            phone: place.phoneNumber,
            website: place.website?.absoluteString,
            googlePlaceId: placeId
        )
    }
    
    // MARK: - Get or Create Course
    
    func getOrCreateCourse(from place: GMSPlace) async throws -> GolfCourse {
        guard let courseInsert = convertToGolfCourseInsert(place) else {
            throw GoogleMapsError.invalidPlace
        }
        
        return try await CourseService.shared.getOrCreateCourse(courseInsert)
    }
    
    // MARK: - Helpers
    
    private func parseAddressComponents(_ components: [GMSAddressComponent]?) -> (city: String, state: String, country: String) {
        var city = ""
        var state = ""
        var country = ""
        
        components?.forEach { component in
            if component.types.contains("locality") {
                city = component.name
            } else if component.types.contains("administrative_area_level_1") {
                state = component.shortName ?? component.name
            } else if component.types.contains("country") {
                country = component.name
            }
        }
        
        return (city, state, country)
    }
}

enum GoogleMapsError: LocalizedError {
    case placeNotFound
    case invalidPlace
    
    var errorDescription: String? {
        switch self {
        case .placeNotFound:
            return "Place not found."
        case .invalidPlace:
            return "Invalid place data."
        }
    }
}
