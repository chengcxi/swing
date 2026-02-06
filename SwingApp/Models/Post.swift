import Foundation

struct Post: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var user: User? // Populated via join
    var roundId: UUID?
    var round: Round? // Populated via join
    var caption: String
    var imageUrl: String?
    var timestamp: Date
    
    // Auxiliary for UI counters, often fetched via count
    var likesCount: Int?
    var commentsCount: Int?
    var isLiked: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case user = "profiles" // When fetching, we can alias or use custom decoding.
        case roundId = "round_id"
        case round = "rounds"
        case caption
        case imageUrl = "image_url"
        case timestamp = "created_at"
        // likes/comments might be separate or computed
    }
    
    static let mocks: [Post] = [
        Post(id: UUID(), userId: User.mock.id, user: User.mock, roundId: Round.mocks[0].id, round: Round.mocks[0], caption: "Tough day at Riviera but always a blast! ⛳️", imageUrl: nil, timestamp: Date(), likesCount: 24, commentsCount: 5, isLiked: false),
        Post(id: UUID(), userId: User.mock.id, user: User.mock, roundId: Round.mocks[1].id, round: Round.mocks[1], caption: "Beautiful views at Sandpiper.", imageUrl: nil, timestamp: Date().addingTimeInterval(-3600), likesCount: 112, commentsCount: 12, isLiked: true)
    ]
}
