import Foundation

struct Comment: Identifiable, Codable {
    let id: UUID
    let authorId: String
    let authorName: String
    let authorAvatar: String
    let text: String
    let timestamp: Date
}
