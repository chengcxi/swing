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
    var yardage: Int?
    let createdAt: Date
    var updatedAt: Date
    
    // Computed
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
        case latitude, longitude, holes, par, slope, yardage
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
    var googlePlaceId: String?
    
    enum CodingKeys: String, CodingKey {
        case name, address, city, state, country
        case latitude, longitude, holes, par, slope
        case phone, website
        case courseRating = "course_rating"
        case googlePlaceId = "google_place_id"
    }
}

struct FavoriteCourse: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let courseId: UUID
    var rank: Int
    let createdAt: Date
    var course: GolfCourse?
    
    enum CodingKeys: String, CodingKey {
        case id, rank, course
        case userId = "user_id"
        case courseId = "course_id"
        case createdAt = "created_at"
    }
}

struct CoursePreference: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let winnerId: UUID
    let loserId: UUID
    let createdAt: Date
    var winner: GolfCourse?
    var loser: GolfCourse?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case winnerId = "winner_id"
        case loserId = "loser_id"
        case createdAt = "created_at"
        case winner, loser
    }
}