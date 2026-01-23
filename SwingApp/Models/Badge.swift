import Foundation

struct Badge: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String // SystemImage name or Asset name
    let description: String
    let dateEarned: Date
}
