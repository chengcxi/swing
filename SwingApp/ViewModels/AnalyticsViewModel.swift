import SwiftUI
import Combine

class AnalyticsViewModel: ObservableObject {
    @Published var selectedCourseFilter: String = "All"
    @Published var scores: [(date: String, score: Int)] = []
    
    let allRounds: [GolfRound]
    
    init(rounds: [GolfRound] = []) {
        // Mock Data if empty
        if rounds.isEmpty {
            self.allRounds = [
                GolfRound(courseName: "Pebble Beach", location: "CA", holes: 18, date: "2023-01-01", score: 82),
                GolfRound(courseName: "Augusta National", location: "GA", holes: 18, date: "2023-02-15", score: 78),
                GolfRound(courseName: "Pebble Beach", location: "CA", holes: 18, date: "2023-03-10", score: 79),
                GolfRound(courseName: "St Andrews", location: "UK", holes: 18, date: "2023-04-20", score: 85),
                GolfRound(courseName: "Pebble Beach", location: "CA", holes: 18, date: "2023-05-05", score: 76)
            ]
        } else {
            self.allRounds = rounds
        }
        
        filterScores()
    }
    
    func filterScores() {
        if selectedCourseFilter == "All" {
            self.scores = allRounds.map { ($0.date, $0.score) }
        } else {
            self.scores = allRounds.filter { $0.courseName == selectedCourseFilter }.map { ($0.date, $0.score) }
        }
    }
    
    var availableCourses: [String] {
        var courses = Set(allRounds.map { $0.courseName })
        return ["All"] + Array(courses).sorted()
    }
}
