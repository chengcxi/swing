import Foundation

struct Round: Identifiable, Codable {
    let id: UUID
    var userId: UUID // Added to link to User
    var courseId: UUID?
    var courseName: String?
    var location: String?
    var score: Int
    var date: Date
    var holes: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case courseId = "course_id"
        case courseName = "course_name"
        case location
        case score
        case date
        case holes
    }
    
    // Mocks updated to include userId placeholder
    static let mocks: [Round] = [
        Round(id: UUID(), userId: UUID(), courseId: UUID(), courseName: "Riviera Country Club", location: "Pacific Palisades, CA", score: 103, date: Date().addingTimeInterval(-86400 * 5), holes: 18),
        Round(id: UUID(), userId: UUID(), courseId: UUID(), courseName: "Sandpiper Golf Club", location: "Goleta, CA", score: 87, date: Date().addingTimeInterval(-86400 * 20), holes: 18),
        Round(id: UUID(), userId: UUID(), courseId: UUID(), courseName: "Rusic Canyon Golf Course", location: "Moorpark, CA", score: 92, date: Date().addingTimeInterval(-86400 * 30), holes: 18)
    ]
}
