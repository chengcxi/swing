// NOT USED YET
// TODO: Implement once backend ready

import Foundation

struct ClubDistance: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    var clubType: ClubType
    var averageDistance: Int
    var maxDistance: Int?
    var minDistance: Int?
    var measurementCount: Int
    let createdAt: Date
    var updatedAt: Date
    
    enum ClubType: String, Codable, CaseIterable {
        case driver = "Driver"
        case threeWood = "3 Wood"
        case fiveWood = "5 Wood"
        case hybrid = "Hybrid"
        case twoIron = "2 Iron"
        case threeIron = "3 Iron"
        case fourIron = "4 Iron"
        case fiveIron = "5 Iron"
        case sixIron = "6 Iron"
        case sevenIron = "7 Iron"
        case eightIron = "8 Iron"
        case nineIron = "9 Iron"
        case pitchingWedge = "PW"
        case gapWedge = "GW"
        case sandWedge = "SW"
        case lobWedge = "LW"
        case putter = "Putter"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case clubType = "club_type"
        case averageDistance = "average_distance"
        case maxDistance = "max_distance"
        case minDistance = "min_distance"
        case measurementCount = "measurement_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ClubDistanceInsert: Codable {
    let userId: UUID
    var clubType: ClubDistance.ClubType
    var averageDistance: Int
    var maxDistance: Int?
    var minDistance: Int?
    var measurementCount: Int = 1
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case clubType = "club_type"
        case averageDistance = "average_distance"
        case maxDistance = "max_distance"
        case minDistance = "min_distance"
        case measurementCount = "measurement_count"
    }
}