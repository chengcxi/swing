import Foundation

enum GolfAction: String, Codable {
    case posted
    case played
    case commentedOn = "commented on"
    case joined
}

struct GolfActivity: Identifiable, Codable {
    let id: Int
    let user: String
    let userAvatar: String
    let action: GolfAction
    let details: String
    let target: String?
    let timestamp: String
}
