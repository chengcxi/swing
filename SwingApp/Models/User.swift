import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var username: String?
    var fullName: String?
    var isVerified: Bool
    var profileImageName: String?
    var university: String?
    var handicap: Double?
    var averageScore: Double?
    var bestRound: Int?
    var roundsPlayed: Int
    var badges: [Badge]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case isVerified = "is_verified"
        case profileImageName = "avatar_url"
        case university
        case handicap
        case averageScore = "average_score"
        case bestRound = "best_round"
        case roundsPlayed = "rounds_played"
        case badges
    }
    
    // Default / Mock data can remain but initialized differently
    static let mock = User(
        id: UUID(),
        username: "@johndoe",
        fullName: "John Doe",
        isVerified: true,
        profileImageName: "profile_placeholder",
        university: "UCLA",
        handicap: 2.1,
        averageScore: 74.5,
        bestRound: 68,
        roundsPlayed: 44,
        badges: [.verified, .top10, .star]
    )
}

enum Badge: String, Codable {
    case verified
    case top10
    case star
    case streak
}
