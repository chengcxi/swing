import Foundation

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var username: String
    var fullName: String?
    var avatarUrl: String?
    var bannerUrl: String?
    var bio: String?
    var handicap: Double?
    var universityId: UUID?
    var universityEmail: String?
    var isUniversityVerified: Bool
    let createdAt: Date
    var updatedAt: Date
    
    // Joined relations
    var university: University?
    var stats: ProfileStats?
    
    var displayName: String { fullName ?? username }
    
    var handicapDisplay: String {
        guard let handicap = handicap else { return "N/A" }
        if handicap > 0 {
            return "+\(String(format: "%.1f", handicap))"
        }
        return String(format: "%.1f", handicap)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, username, bio, handicap, university, stats
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case bannerUrl = "banner_url"
        case universityId = "university_id"
        case universityEmail = "university_email"
        case isUniversityVerified = "is_university_verified"
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
    var bannerUrl: String?
    var bio: String?
    var handicap: Double?
    var universityId: UUID?
    var universityEmail: String?
    var isUniversityVerified: Bool?
    
    enum CodingKeys: String, CodingKey {
        case username, bio, handicap
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case bannerUrl = "banner_url"
        case universityId = "university_id"
        case universityEmail = "university_email"
        case isUniversityVerified = "is_university_verified"
    }
}

struct ProfileStats: Codable, Hashable {
    let totalRounds: Int
    let averageScore: Double?
    let bestScore: Int?
    let handicap: Double?
    let coursesPlayed: Int
    // TODO: Add features back once backend ready
    // let totalBirdies: Int
    // let totalEagles: Int
    // let totalPars: Int
    // let totalBogeys: Int
    // let averagePutts: Double?
    // let fairwayPercentage: Double?
    // let girPercentage: Double?
    
    var averageScoreDisplay: String {
        guard let avg = averageScore else { return "N/A" }
        return String(format: "%.1f", avg)
    }
    
    enum CodingKeys: String, CodingKey {
        case totalRounds = "total_rounds"
        case averageScore = "average_score"
        case bestScore = "best_score"
        case handicap
        case coursesPlayed = "courses_played"
        // case totalBirdies = "total_birdies"
        // case totalEagles = "total_eagles"
        // case totalPars = "total_pars"
        // case totalBogeys = "total_bogeys"
        // case averagePutts = "average_putts"
        // case fairwayPercentage = "fairway_percentage"
        // case girPercentage = "gir_percentage"
    }
}