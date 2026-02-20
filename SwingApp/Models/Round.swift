import Foundation

struct Round: Identifiable {
    let id: UUID
    var courseId: UUID
    var courseName: String
    var location: String
    var score: Int
    var date: Date
    var holes: Int
    var holeScores: [HoleScoreEntry]?

    static let mocks: [Round] = [
        Round(id: UUID(), courseId: UUID(), courseName: "Riviera Country Club", location: "Pacific Palisades, CA", score: 103, date: Date().addingTimeInterval(-86400 * 5), holes: 18),
        Round(id: UUID(), courseId: UUID(), courseName: "Sandpiper Golf Club", location: "Goleta, CA", score: 87, date: Date().addingTimeInterval(-86400 * 20), holes: 18),
        Round(id: UUID(), courseId: UUID(), courseName: "Rustic Canyon Golf Course", location: "Moorpark, CA", score: 92, date: Date().addingTimeInterval(-86400 * 30), holes: 18)
    ]
}

struct HoleScoreEntry: Identifiable {
    let id: UUID
    var holeNumber: Int
    var par: Int
    var score: Int

    var scoreToPar: Int { score - par }

    var scoreLabel: String {
        switch scoreToPar {
        case ...(-2): return "Eagle+"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Dbl Bogey"
        default: return "+\(scoreToPar)"
        }
    }

    init(holeNumber: Int, par: Int, score: Int) {
        self.id = UUID()
        self.holeNumber = holeNumber
        self.par = par
        self.score = score
    }
}
