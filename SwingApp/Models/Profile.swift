import Foundation

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var username: String
    var fullName: String?
    var avatarUrl: String?
    var handicap: Double?
    var bio: String?
    var homeCourseId: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    var displayName: String {
        fullName ?? username
    }
    
    var handicapDisplay: String {
        guard let handicap = handicap else { return "N/A" }
        return String(format: "%.1f", handicap)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, username, handicap, bio
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case homeCourseId = "home_course_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProfileInsert: Codable {
    let id: UUID
    let username: String
    var fullName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case fullName = "full_name"
    }
}

struct ProfileUpdate: Codable {
    var username: String?
    var fullName: String?
    var avatarUrl: String?
    var handicap: Double?
    var bio: String?
    var homeCourseId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case username, handicap, bio
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case homeCourseId = "home_course_id"
    }
}
