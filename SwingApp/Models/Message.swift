import Foundation

struct Conversation: Identifiable, Codable {
    let id: String
    let participantName: String
    let participantAvatar: String
    let lastMessage: String
    let timestamp: String
    let unreadCount: Int
    let isGroup: Bool
}
