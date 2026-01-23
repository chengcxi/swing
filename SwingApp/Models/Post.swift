import Foundation

struct Post: Identifiable, Codable {
    let id: Int
    let author: String
    let authorUsername: String
    let authorAvatar: String
    let timestamp: String
    let content: String
    let image: String?
    var likes: Int
    var likesList: [String] = [] // User IDs
    var comments: Int
    var commentsList: [Comment] = []
    let taggedUsers: [String]?
    let taggedCourses: [String]?
    let roundId: UUID? // Linked GolfRound
}
