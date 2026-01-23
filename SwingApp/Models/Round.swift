import Foundation

struct Round: Identifiable {
    let id: UUID
    var courseId: UUID
    var courseName: String
    var location: String
    var score: Int
    var date: Date
    var holes: Int
    
    static let mocks: [Round] = [
        Round(id: UUID(), courseId: UUID(), courseName: "Riviera Country Club", location: "Pacific Palisades, CA", score: 103, date: Date().addingTimeInterval(-86400 * 5), holes: 18),
        Round(id: UUID(), courseId: UUID(), courseName: "Sandpiper Golf Club", location: "Goleta, CA", score: 87, date: Date().addingTimeInterval(-86400 * 20), holes: 18),
        Round(id: UUID(), courseId: UUID(), courseName: "Rusic Canyon Golf Course", location: "Moorpark, CA", score: 92, date: Date().addingTimeInterval(-86400 * 30), holes: 18)
    ]
}
