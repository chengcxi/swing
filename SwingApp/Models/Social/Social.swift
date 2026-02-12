import Foundation

// MARK: - Comment
struct Comment: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let roundId: UUID
    var content: String
    let createdAt: Date
    var updatedAt: Date
    var user: Profile?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, user
        case userId = "user_id"
        case roundId = "round_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CommentInsert: Codable {
    let userId: UUID
    let roundId: UUID
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case content
        case userId = "user_id"
        case roundId = "round_id"
    }
}

// MARK: - Follow
struct Follow: Codable, Hashable {
    let followerId: UUID
    let followingId: UUID
    let createdAt: Date
    var follower: Profile?
    var following: Profile?
    
    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
        case follower, following
    }
}

// MARK: - Like
struct Like: Codable, Hashable {
    let userId: UUID
    let roundId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case roundId = "round_id"
        case createdAt = "created_at"
    }
}

// MARK: - Statistics
struct UserStats {
    let totalRounds: Int
    let averageScore: Double?
    let bestScore: Int?
    let coursesPlayed: Int
    
    var averageScoreDisplay: String {
        guard let avg = averageScore else { return "N/A" }
        return String(format: "%.1f", avg)
    }
}

struct FollowCounts {
    let followers: Int
    let following: Int
}
