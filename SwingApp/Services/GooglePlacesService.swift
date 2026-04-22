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
    
    enum CodingKeys: String, CodingKey {
        case name
        case formattedAddress = "formatted_address"
        case geometry
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
            // Mocking some data that Google Places doesn't easily provide in textsearch
            Course(
                id: UUID(),
                name: place.name,
                location: place.formattedAddress ?? "Unknown Location",
                holes: 18,
                par: 72,
                difficulty: Double.random(in: 3.0...10.0), // Mock difficulty
                hasDrivingRange: Bool.random(),
                hasPuttingGreen: Bool.random()
            )
        }
    }
}
