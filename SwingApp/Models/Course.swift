import Foundation

struct Course: Identifiable, Codable {
    let id: UUID
    var name: String
    var location: String?
    var holes: Int
    var difficulty: Double?
    var hasDrivingRange: Bool
    var latitude: Double?
    var longitude: Double?
    var googlePlaceId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case holes
        case difficulty
        case hasDrivingRange = "has_driving_range"
        case hasPuttingGreen = "has_putting_green"
        case latitude
        case longitude
        case googlePlaceId = "google_place_id"
    }
    
    static let mocks: [Course] = [
        Course(id: UUID(), name: "Los Robles Greens", location: "Thousand Oaks, CA", holes: 18, difficulty: 7.1, hasDrivingRange: true, hasPuttingGreen: true, latitude: 34.168, longitude: -118.887, googlePlaceId: nil),
        Course(id: UUID(), name: "Westlake Golf Course", location: "Westlake Village, CA", holes: 18, difficulty: 6.2, hasDrivingRange: true, hasPuttingGreen: true, latitude: 34.148, longitude: -118.807, googlePlaceId: nil),
        Course(id: UUID(), name: "Sandpiper Golf Club", location: "Goleta, CA", holes: 18, difficulty: 7.4, hasDrivingRange: false, hasPuttingGreen: true, latitude: 34.425, longitude: -119.920, googlePlaceId: nil)
    ]
}
