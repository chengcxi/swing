import Foundation

struct Course: Identifiable {
    let id: UUID
    var name: String
    var location: String
    var holes: Int
    var difficulty: Double
    var hasDrivingRange: Bool
    var hasPuttingGreen: Bool
    
    static let mocks: [Course] = [
        Course(id: UUID(), name: "Los Robles Greens", location: "Thousand Oaks, CA", holes: 18, difficulty: 7.1, hasDrivingRange: true, hasPuttingGreen: true),
        Course(id: UUID(), name: "Westlake Golf Course", location: "Westlake Village, CA", holes: 18, difficulty: 6.2, hasDrivingRange: true, hasPuttingGreen: true),
        Course(id: UUID(), name: "Sandpiper Golf Club", location: "Goleta, CA", holes: 18, difficulty: 7.4, hasDrivingRange: false, hasPuttingGreen: true)
    ]
}
