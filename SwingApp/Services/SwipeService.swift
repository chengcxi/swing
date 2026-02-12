import Foundation

@MainActor
class SwipeService: ObservableObject {
    static let shared = SwipeService()
    
    @Published var currentPair: (GolfCourse, GolfCourse)?
    @Published var courseRankings: [GolfCourse] = []
    @Published var isLoading = false
    
    // MARK: - Get Random Course Pair
    
    func getRandomCoursePair(userId: UUID) async throws -> (GolfCourse, GolfCourse)? {
        // Get courses the user has played
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select("course_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        let courseIds = Array(Set(rounds.map { $0.courseId }))
        
        guard courseIds.count >= 2 else { return nil }
        
        let courses: [GolfCourse] = try await supabase
            .from("golf_courses")
            .select()
            .in("id", values: courseIds.map { $0.uuidString })
            .execute()
            .value
        
        guard courses.count >= 2 else { return nil }
        
        // Random selection
        let shuffled = courses.shuffled()
        let pair = (shuffled[0], shuffled[1])
        currentPair = pair
        return pair
    }
    
    // MARK: - Record Preference (Swipe)
    
    func recordPreference(winnerId: UUID, loserId: UUID) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        try await supabase
            .from("course_preferences")
            .insert([
                "user_id": userId.uuidString,
                "winner_id": winnerId.uuidString,
                "loser_id": loserId.uuidString
            ])
            .execute()
        
        // Recalculate rankings
        _ = try await calculateCourseRankings(userId: userId)
    }
    
    // MARK: - Calculate Course Rankings (ELO-style)
    
    func calculateCourseRankings(userId: UUID) async throws -> [GolfCourse] {
        // Get all preferences
        let preferences: [CoursePreference] = try await supabase
            .from("course_preferences")
            .select("*, winner:golf_courses!winner_id(*), loser:golf_courses!loser_id(*)")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        // Get unique courses
        var courseScores: [UUID: (course: GolfCourse, wins: Int, losses: Int)] = [:]
        
        for pref in preferences {
            if let winner = pref.winner {
                if courseScores[pref.winnerId] == nil {
                    courseScores[pref.winnerId] = (winner, 0, 0)
                }
                courseScores[pref.winnerId]?.wins += 1
            }
            
            if let loser = pref.loser {
                if courseScores[pref.loserId] == nil {
                    courseScores[pref.loserId] = (loser, 0, 0)
                }
                courseScores[pref.loserId]?.losses += 1
            }
        }
        
        // Rank by win percentage
        let ranked = courseScores.values
            .map { ($0.course, Double($0.wins) / Double(max(1, $0.wins + $0.losses))) }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
        
        courseRankings = ranked
        return ranked
    }
    
    // MARK: - Skip Pair
    
    func skipCurrentPair(userId: UUID) async throws {
        _ = try await getRandomCoursePair(userId: userId)
    }
}