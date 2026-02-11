import Foundation

@MainActor
class RoundService: ObservableObject {
    static let shared = RoundService()
    
    @Published var userRounds: [Round] = []
    @Published var feedRounds: [Round] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var feedOffset = 0
    private var hasMoreFeed = true
    
    // MARK: - Create Round
    
    func createRound(_ round: RoundInsert) async throws -> Round {
        isLoading = true
        defer { isLoading = false }
        
        let newRound: Round = try await supabase
            .from("rounds")
            .insert(round)
            .select("*, course:golf_courses(*), user:profiles(*)")
            .single()
            .execute()
            .value
        
        userRounds.insert(newRound, at: 0)
        feedRounds.insert(newRound, at: 0)
        
        return newRound
    }
    
    // MARK: - Fetch User Rounds
    
    func fetchUserRounds(userId: UUID) async throws -> [Round] {
        isLoading = true
        defer { isLoading = false }
        
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select("*, course:golf_courses(*), user:profiles(*)")
            .eq("user_id", value: userId.uuidString)
            .order("date_played", ascending: false)
            .execute()
            .value
        
        if userId == AuthService.shared.currentUser?.id {
            userRounds = rounds
        }
        
        return rounds
    }
    
    // MARK: - Fetch Single Round
    
    func fetchRound(id: UUID) async throws -> Round {
        let round: Round = try await supabase
            .from("rounds")
            .select("*, course:golf_courses(*), user:profiles(*)")
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return round
    }
    
    // MARK: - Global Feed
    
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
    
    // MARK: - Following Feed
    
    func fetchFollowingFeed(userId: UUID, limit: Int = 20, offset: Int = 0) async throws -> [Round] {
        let follows: [Follow] = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId.uuidString)
            .execute()
            .value
        
        let followingIds = follows.map { $0.followingId.uuidString }
        
        guard !followingIds.isEmpty else { return [] }
        
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select("*, course:golf_courses(*), user:profiles(*)")
            .in("user_id", values: followingIds)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return rounds
    }
    
    // MARK: - Update Round
    
    func updateRound(id: UUID, update: RoundUpdate) async throws -> Round {
        let round: Round = try await supabase
            .from("rounds")
            .update(update)
            .eq("id", value: id.uuidString)
            .select("*, course:golf_courses(*), user:profiles(*)")
            .single()
            .execute()
            .value
        
        if let index = userRounds.firstIndex(where: { $0.id == id }) {
            userRounds[index] = round
        }
        if let index = feedRounds.firstIndex(where: { $0.id == id }) {
            feedRounds[index] = round
        }
        
        return round
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
    }
    
    // MARK: - User Statistics
    
    func fetchUserStats(userId: UUID) async throws -> UserStats {
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select("score, course_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        guard !rounds.isEmpty else {
            return UserStats(
                totalRounds: 0,
                averageScore: nil,
                bestScore: nil,
                coursesPlayed: 0
            )
        }
        
        let scores = rounds.map { $0.score }
        let uniqueCourses = Set(rounds.map { $0.courseId }).count
        
        return UserStats(
            totalRounds: rounds.count,
            averageScore: Double(scores.reduce(0, +)) / Double(scores.count),
            bestScore: scores.min(),
            coursesPlayed: uniqueCourses
        )
    }
}
