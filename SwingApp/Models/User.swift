import Foundation

struct User: Identifiable, Codable {
    let id: String
    let name: String
    let username: String
    let avatar: String
    let isVerified: Bool
    let isPro: Bool
    let description: String?
    let favoriteCourse: String?
    let university: String?
    let eduEmail: String?
    let handicap: Double?
    
    // New Features
    var badges: [Badge] = []
    var playingStreak: Int = 0
    var universityRank: Int? = nil // Only if top 10
    var schoolId: String? = nil
}

struct UserStats: Codable {
    let bestRound: Int
    let averageScore: Double
    let roundsPlayed: Int
    let handicap: Double
}
