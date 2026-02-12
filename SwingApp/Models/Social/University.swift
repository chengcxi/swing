import Foundation

struct University: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var shortName: String?
    var emailDomain: String
    var logoUrl: String?
    var primaryColor: String?
    var secondaryColor: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case shortName = "short_name"
        case emailDomain = "email_domain"
        case logoUrl = "logo_url"
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case createdAt = "created_at"
    }
}

struct UniversityRanking: Codable, Identifiable {
    var id: UUID { userId }
    let userId: UUID
    let universityId: UUID
    let rank: Int
    let handicap: Double
    var user: Profile?
    var university: University?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case universityId = "university_id"
        case rank, handicap, user, university
    }
}

struct UniversityLeaderboard: Codable {
    let university: University
    let rankings: [UniversityRanking]
    let totalMembers: Int
    let averageHandicap: Double?
}