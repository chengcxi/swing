import Foundation

struct Post: Identifiable {
    let id: UUID
    var user: User
    var round: Round?
    var caption: String
    var timestamp: Date
    var likes: Int
    var comments: Int
    var isLiked: Bool
    
    static let mocks: [Post] = [
        Post(id: UUID(), user: User.mock, round: Round.mocks[0], caption: "Tough day at Riviera but always a blast! ⛳️", timestamp: Date(), likes: 24, comments: 5, isLiked: false),
        Post(id: UUID(), user: User.mock, round: Round.mocks[1], caption: "Beautiful views at Sandpiper.", timestamp: Date().addingTimeInterval(-3600), likes: 112, comments: 12, isLiked: true)
    ]
}
