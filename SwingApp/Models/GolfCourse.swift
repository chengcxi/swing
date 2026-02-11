import Foundation
import CoreLocation

struct GolfCourse: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var address: String
    var city: String
    var state: String
    var country: String
    var latitude: Double
    var longitude: Double
    var holes: Int
    var par: Int?
    var courseRating: Double?
    var slope: Int?
    var phone: String?
    var website: String?
    var description: String?
    var imageUrl: String?
    var googlePlaceId: String?
    let createdAt: Date
    var updatedAt: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var fullAddress: String {
        [address, city, state, country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, city, state, country
        case latitude, longitude, holes, par, slope
        case phone, website, description
        case courseRating = "course_rating"
        case imageUrl = "image_url"
        case googlePlaceId = "google_place_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct GolfCourseInsert: Codable {
    var name: String
    var address: String
    var city: String
    var state: String
    var country: String
    var latitude: Double
    var longitude: Double
    var holes: Int = 18
    var par: Int?
    var courseRating: Double?
    var slope: Int?
    var phone: String?
    var website: String?
    var description: String?
    var imageUrl: String?
    var googlePlaceId: String?
    
    enum CodingKeys: String, CodingKey {
        case name, address, city, state, country
        case latitude, longitude, holes, par, slope
        case phone, website, description
        case courseRating = "course_rating"
        case imageUrl = "image_url"
        case googlePlaceId = "google_place_id"
    }
}
