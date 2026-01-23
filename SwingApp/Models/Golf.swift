import Foundation

struct GolfRound: Identifiable, Codable {
    var id: UUID = UUID() // Added for Identifiable conformance
    let courseName: String
    let location: String
    let holes: Int
    let date: String // ISO string or formatted date
    let score: Int
    var holeScores: [Int]? // Optional hole-by-hole scores
    var calculatedTotal: Int {
        if let holes = holeScores, !holes.isEmpty {
            return holes.reduce(0, +)
        }
        return score
    }
    
    enum CodingKeys: String, CodingKey {
        case courseName, location, holes, date, score
    }
}

struct CourseRanking: Identifiable, Codable {
    var id: UUID = UUID()
    let rank: Int
    let courseName: String
    let location: String
    
    enum CodingKeys: String, CodingKey {
        case rank, courseName, location
    }
}

struct GolfCourse: Identifiable, Codable {
    let id: String
    let name: String
    let location: String
    let holes: Int // 9 | 18
    let difficulty: Double
    let facilities: CourseFacilities
    let imageUrl: String
    let rating: Double
}

struct CourseFacilities: Codable {
    let drivingRange: Bool
    let puttingGreen: Bool
}

struct CourseReview: Identifiable, Codable {
    let id: String
    let courseId: String
    let author: String
    let authorAvatar: String
    let rating: Double
    let comment: String
    let timestamp: String
}
