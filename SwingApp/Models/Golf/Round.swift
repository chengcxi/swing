import Foundation

struct Round: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let courseId: UUID
    var score: Int
    var datePlayed: Date
    // var teeBox: String?
    // var notes: String?
    // var weather: String?
    var photos: [String]?
    // var totalPutts: Int?
    // var fairwaysHit: Int?
    // var fairwaysTotal: Int?
    // var greensInRegulation: Int?
    // var greensTotal: Int?
    // var penalties: Int?
    let createdAt: Date
    var updatedAt: Date
    
    // Joined relations
    var course: GolfCourse?
    var user: Profile?
    var holeScores: [HoleScore]?
    var likesCount: Int?
    var commentsCount: Int?
    var isLikedByCurrentUser: Bool?
    
    // Computed
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
    
    // var fairwayPercentage: Double? {
    //     guard let hit = fairwaysHit, let total = fairwaysTotal, total > 0 else { return nil }
    //     return Double(hit) / Double(total) * 100
    // }
    
    // var girPercentage: Double? {
    //     guard let gir = greensInRegulation, let total = greensTotal, total > 0 else { return nil }
    //     return Double(gir) / Double(total) * 100
    // }
    
    var handicapDifferential: Double? {
        guard let rating = course?.courseRating, let slope = course?.slope else { return nil }
        return (Double(score) - rating) * 113 / Double(slope)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, score, photos
        case userId = "user_id"
        case courseId = "course_id"
        case datePlayed = "date_played"
        // case teeBox = "tee_box"
        // case totalPutts = "total_putts"
        // case fairwaysHit = "fairways_hit"
        // case fairwaysTotal = "fairways_total"
        // case greensInRegulation = "greens_in_regulation"
        // case greensTotal = "greens_total"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case course, user
        case holeScores = "hole_scores"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case isLikedByCurrentUser = "is_liked_by_current_user"
    }
}

struct RoundInsert: Codable {
    let userId: UUID
    let courseId: UUID
    var score: Int
    var datePlayed: Date
    // var teeBox: String?
    // var notes: String?
    // var weather: String?
    var photos: [String]?
    // var totalPutts: Int?
    // var fairwaysHit: Int?
    // var fairwaysTotal: Int?
    // var greensInRegulation: Int?
    // var greensTotal: Int?
    // var penalties: Int?
    
    enum CodingKeys: String, CodingKey {
        case score, photos
        case userId = "user_id"
        case courseId = "course_id"
        case datePlayed = "date_played"
        // case teeBox = "tee_box"
        // case totalPutts = "total_putts"
        // case fairwaysHit = "fairways_hit"
        // case fairwaysTotal = "fairways_total"
        // case greensInRegulation = "greens_in_regulation"
        // case greensTotal = "greens_total"
    }
}