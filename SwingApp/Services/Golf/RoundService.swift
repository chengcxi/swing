import Foundation

@MainActor
class RoundService: ObservableObject {
    static let shared = RoundService()
    
    @Published var userRounds: [Round] = []
    @Published var feedRounds: [Round] = []
    @Published var isLoading = false
    
    private var feedOffset = 0
    private var hasMoreFeed = true
    
    // MARK: - Create Round with Hole Scores
    
    func createRound(_ round: RoundInsert, holeScores: [HoleScoreInsert]? = nil) async throws -> Round {
        isLoading = true
        defer { isLoading = false }
        
        // Insert round
        let newRound: Round = try await supabase
            .from("rounds")
            .insert(round)
            .select("*, course:golf_courses(*), user:profiles(*)")
            .single()
            .execute()
            .value
        
        // Insert hole scores if provided
        if let scores = holeScores {
            let scoresWithRoundId = scores.map { score -> HoleScoreInsert in
                HoleScoreInsert(
                    roundId: newRound.id,
                    holeNumber: score.holeNumber,
                    par: score.par,
                    score: score.score,
                    putts: score.putts,
                    fairwayHit: score.fairwayHit,
                    greenInRegulation: score.greenInRegulation,
                    penalties: score.penalties,
                    clubUsedOffTee: score.clubUsedOffTee,
                    notes: score.notes
                )
            }
            
            try await supabase
                .from("hole_scores")
                .insert(scoresWithRoundId)
                .execute()
        }
        
        // Recalculate handicap
        try await recalculateHandicap()
        
        userRounds.insert(newRound, at: 0)
        feedRounds.insert(newRound, at: 0)
        
        return newRound
    }
    
    // MARK: - Fetch Rounds
    
    func fetchUserRounds(userId: UUID) async throws -> [Round] {
        isLoading = true
        defer { isLoading = false }
        
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select("*, course:golf_courses(*), user:profiles(*), hole_scores(*)")
            .eq("user_id", value: userId.uuidString)
            .order("date_played", ascending: false)
            .execute()
            .value
        
        if userId == AuthService.shared.currentUser?.id {
            userRounds = rounds
        }
        
        return rounds
    }
    
    func fetchRound(id: UUID) async throws -> Round {
        let round: Round = try await supabase
            .from("rounds")
            .select("*, course:golf_courses(*), user:profiles(*), hole_scores(*)")
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return round
    }
    
    // MARK: - Feed
    
    func fetchFeed(refresh: Bool = false) async throws -> [Round] {
        if refresh {
            feedOffset = 0
            hasMoreFeed = true
        }
        
        guard hasMoreFeed else { return feedRounds }
        
        isLoading = true
        defer { isLoading = false }
        
        let pageSize = Config.feedPageSize
        
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select("*, course:golf_courses(*), user:profiles(*)")
            .order("created_at", ascending: false)
            .range(from: feedOffset, to: feedOffset + pageSize - 1)
            .execute()
            .value
        
        if rounds.count < pageSize {
            hasMoreFeed = false
        }
        
        if refresh {
            feedRounds = rounds
        } else {
            feedRounds.append(contentsOf: rounds)
        }
        
        feedOffset += rounds.count
        return rounds
    }
    
    // MARK: - Delete Round
    
    func deleteRound(id: UUID) async throws {
        try await supabase
            .from("rounds")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        userRounds.removeAll { $0.id == id }
        feedRounds.removeAll { $0.id == id }
        
        try await recalculateHandicap()
    }
    
    // MARK: - Handicap Calculation
    
    func recalculateHandicap() async throws {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        
        // Get last 20 rounds with course info
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select("*, course:golf_courses(course_rating, slope)")
            .eq("user_id", value: userId.uuidString)
            .order("date_played", ascending: false)
            .limit(20)
            .execute()
            .value
        
        guard rounds.count >= 5 else {
            // Need at least 5 rounds
            return
        }
        
        // Calculate differentials
        let differentials = rounds.compactMap { round -> Double? in
            guard let rating = round.course?.courseRating,
                  let slope = round.course?.slope else { return nil }
            return (Double(round.score) - rating) * 113 / Double(slope)
        }
        
        guard !differentials.isEmpty else { return }
        
        // Use best differentials based on count
        let numToUse: Int
        switch differentials.count {
        case 5...6: numToUse = 1
        case 7...8: numToUse = 2
        case 9...10: numToUse = 3
        case 11...12: numToUse = 4
        case 13...14: numToUse = 5
        case 15...16: numToUse = 6
        case 17: numToUse = 7
        case 18: numToUse = 8
        case 19: numToUse = 9
        default: numToUse = 10
        }
        
        let sorted = differentials.sorted()
        let best = Array(sorted.prefix(numToUse))
        let average = best.reduce(0, +) / Double(best.count)
        let handicap = average * Config.handicapMultiplier
        
        // Update profile
        try await AuthService.shared.updateProfile(ProfileUpdate(handicap: handicap))
    }
}