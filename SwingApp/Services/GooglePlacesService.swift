import Foundation
import CoreLocation

enum GooglePlacesError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
}

struct PlacesResponse: Codable {
    let results: [PlaceResult]
    let status: String
}

struct PlaceResult: Codable {
    let name: String
    let formattedAddress: String?
    let geometry: PlaceGeometry?
    let placeId: String?

    enum CodingKeys: String, CodingKey {
        case name
        case formattedAddress = "formatted_address"
        case geometry
        case placeId = "place_id"
    }
}

struct PlaceGeometry: Codable {
    let location: PlaceLocation
}

struct PlaceLocation: Codable {
    let lat: Double
    let lng: Double
}

class GooglePlacesService {
    static let shared = GooglePlacesService()
    
    private let baseURL = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    private let apiKey = Secrets.googleMapsAPIKey
    
    private init() {}
    
    func searchGolfCourses(query: String) async throws -> [Course] {
        let searchQuery = query.isEmpty ? "golf course" : "\(query) golf course"
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw GooglePlacesError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: searchQuery),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = urlComponents.url else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GooglePlacesError.apiError("Invalid HTTP response")
        }
        
        let decoder = JSONDecoder()
        let placesResponse = try decoder.decode(PlacesResponse.self, from: data)
        
        guard placesResponse.status == "OK" || placesResponse.status == "ZERO_RESULTS" else {
            throw GooglePlacesError.apiError("API Error: \(placesResponse.status)")
        }
        
        // Map to internal Course models
        return placesResponse.results.map { place in
            let (city, state) = parseCityState(from: place.formattedAddress)
            return Course(
                id: UUID(),
                name: place.name,
                location: place.formattedAddress ?? "Unknown Location",
                holes: 18,
                par: 72,
                difficulty: Double.random(in: 3.0...10.0), // Google text-search doesn't return this
                hasDrivingRange: Bool.random(),
                hasPuttingGreen: Bool.random(),
                latitude: place.geometry?.location.lat,
                longitude: place.geometry?.location.lng,
                googlePlaceId: place.placeId,
                city: city,
                state: state
            )
        }
    }

    /// Pull city / state out of a Google formatted_address like
    /// "1234 Main St, Thousand Oaks, CA 91320, USA".
    private func parseCityState(from address: String?) -> (city: String?, state: String?) {
        guard let address = address else { return (nil, nil) }
        let parts = address.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        // Heuristic: city is the second-to-last "real" component before "<STATE ZIP>, COUNTRY"
        // For "Street, City, ST ZIP, Country" → parts.count == 4 → city at index count-3
        guard parts.count >= 3 else {
            return (parts.first, nil)
        }
        let city = parts[parts.count - 3]
        let stateZip = parts[parts.count - 2]
        let state = stateZip.components(separatedBy: " ").first
        return (city, state)
    }
}
