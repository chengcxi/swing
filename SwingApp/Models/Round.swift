import Foundation

struct Round: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let courseId: UUID
    var score: Int
    var datePlayed: Date
    var notes: String?
    var weather: String?
    var photos: [String]?
    var putts: Int?
    var fairwaysHit: Int?
    var greensInRegulation: Int?
    let createdAt: Date
    var updatedAt: Date
    
    // Joined relations
    var course: GolfCourse?
    var user: Profile?
    var likesCount: Int?
    var commentsCount: Int?
    
    var scoreDisplay: String {
        guard let par = course?.par else { return "\(score)" }
        let differential = score - par
        if differential > 0 {
            return "+\(differential)"
        } else if differential < 0 {
            return "\(differential)"
        }
        return "E"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: datePlayed)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    enum CodingKeys: String, CodingKey {
        case id, score, notes, weather, photos, putts
        case userId = "user_id"
        case courseId = "course_id"
        case datePlayed = "date_played"
        case fairwaysHit = "fairways_hit"
        case greensInRegulation = "greens_in_regulation"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case course, user
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
    }
}

struct RoundInsert: Codable {
    let userId: UUID
    let courseId: UUID
    var score: Int
    var datePlayed: Date
    var notes: String?
    var weather: String?
    var photos: [String]?
    var putts: Int?
    var fairwaysHit: Int?
    var greensInRegulation: Int?
    
    enum CodingKeys: String, CodingKey {
        case score, notes, weather, photos, putts
        case userId = "user_id"
        case courseId = "course_id"
        case datePlayed = "date_played"
        case fairwaysHit = "fairways_hit"
        case greensInRegulation = "greens_in_regulation"
    }
}

struct RoundUpdate: Codable {
    var score: Int?
    var datePlayed: Date?
    var notes: String?
    var weather: String?
    var photos: [String]?
    var putts: Int?
    var fairwaysHit: Int?
    var greensInRegulation: Int?
    
    enum CodingKeys: String, CodingKey {
        case score, notes, weather, photos, putts
        case datePlayed = "date_played"
        case fairwaysHit = "fairways_hit"
        case greensInRegulation = "greens_in_regulation"
    }
}
