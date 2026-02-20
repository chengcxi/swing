import Foundation

struct User: Identifiable {
    let id: UUID
    var username: String
    var fullName: String
    var isVerified: Bool
    var profileImageName: String
    var university: String?
    var handicap: Double
    var averageScore: Double
    var bestRound: Int
    var roundsPlayed: Int
    var badges: [Badge]
    var bio: String?
    var friendsCount: Int

    static let mock = User(
        id: UUID(),
        username: "johndoe",
        fullName: "John Doe",
        isVerified: true,
        profileImageName: "profile_placeholder",
        university: "UCLA",
        handicap: 2.1,
        averageScore: 74.5,
        bestRound: 68,
        roundsPlayed: 44,
        badges: [.verified, .top10, .star],
        bio: "UCLA Golfer | Chasing scratch | Always on the course",
        friendsCount: 2
    )
}

enum Badge: String, Codable {
    case verified
    case top10
    case star
}
