import Foundation
import CoreLocation
import GooglePlaces

// Note: Ensure you have added the 'GooglePlaces' package to your project.
// You must also provide your API key in AppDelegate or App initialization:
// GMSPlacesClient.provideAPIKey("YOUR_API_KEY")

class GoogleService {
    static let shared = GoogleService()
    
    private let placesClient = GMSPlacesClient.shared()
    
    private init() {}
    
    // Search for Golf Courses
    func searchGolfCourses(query: String) async throws -> [GooglePlace] {
        return try await withCheckedThrowingContinuation { continuation in
            let filter = GMSAutocompleteFilter()
            filter.type = .establishment
            // filter.locationBias = ... // Can prioritize user location if available
            
            // Note: Efficient way is to filter by text "Golf" or rely on the query being specific. 
            // Google Places API (New) has specific types like 'golf_course'. 
            // The iOS SDK Autocomplete is great for text search.
            
            placesClient.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: nil) { (results, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let places = results?.compactMap { prediction -> GooglePlace? in
                    // Naive filtering: Ensure it looks like a golf related place if query is generic
                    // Or trust the user's query.
                    return GooglePlace(
                        placeId: prediction.placeID,
                        name: prediction.attributedFullText.string,
                        mainText: prediction.attributedPrimaryText.string,
                        secondaryText: prediction.attributedSecondaryText?.string
                    )
                } ?? []
                
                continuation.resume(returning: places)
            }
        }
    }
    
    // Get Details (Lat/Long, etc)
    func getPlaceDetails(placeId: String) async throws -> GooglePlaceDetails {
        return try await withCheckedThrowingContinuation { continuation in
            let fields: GMSPlaceField = [.name, .coordinate, .formattedAddress, .photos]
            
            placesClient.fetchPlace(fromPlaceID: placeId, placeFields: fields, sessionToken: nil) { (place, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let place = place else {
                    continuation.resume(throwing: NSError(domain: "GoogleService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Place not found"]))
                    return
                }
                
                let details = GooglePlaceDetails(
                    placeId: placeId,
                    name: place.name ?? "",
                    address: place.formattedAddress,
                    latitude: place.coordinate.latitude,
                    longitude: place.coordinate.longitude
                )
                
                continuation.resume(returning: details)
            }
        }
    }
}

// Helper Structs
struct GooglePlace: Identifiable {
    var id: String { placeId }
    let placeId: String
    let name: String
    let mainText: String
    let secondaryText: String?
}

struct GooglePlaceDetails {
    let placeId: String
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
}
