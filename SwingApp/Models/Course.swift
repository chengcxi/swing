import Foundation

struct Course: Identifiable {
    let id: UUID
    var name: String
    var location: String
    var holes: Int
    var par: Int
    var difficulty: Double
    var hasDrivingRange: Bool
    var hasPuttingGreen: Bool

    var holePars: [Int] {
        let standard18 = [4, 4, 3, 5, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 3, 4, 5, 4]
        return Array(standard18.prefix(holes))
    }

    static let mocks: [Course] = [
        Course(id: UUID(), name: "Los Robles Greens", location: "Thousand Oaks, CA", holes: 18, par: 72, difficulty: 7.1, hasDrivingRange: true, hasPuttingGreen: true),
        Course(id: UUID(), name: "Westlake Golf Course", location: "Westlake Village, CA", holes: 18, par: 71, difficulty: 6.2, hasDrivingRange: true, hasPuttingGreen: true),
        Course(id: UUID(), name: "Sandpiper Golf Club", location: "Goleta, CA", holes: 18, par: 72, difficulty: 7.4, hasDrivingRange: false, hasPuttingGreen: true)
    ]
}
