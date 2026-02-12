import Foundation

@MainActor
class UniversityService: ObservableObject {
    static let shared = UniversityService()
    
    @Published var universities: [University] = []
    @Published var currentUniversityRankings: [UniversityRanking] = []
    @Published var userRank: Int?
    @Published var isLoading = false
    
    // MARK: - Fetch Universities
    
    func fetchUniversities() async throws -> [University] {
        let universities: [University] = try await supabase
            .from("universities")
            .select()
            .order("name")
            .execute()
            .value
        
        self.universities = universities
        return universities
    }
    
    // MARK: - Link University Email
    
    func linkUniversityEmail(email: String) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        // Extract domain
        guard let domain = email.components(separatedBy: "@").last?.lowercased() else {
            throw UniversityError.invalidEmail
        }
        
        // Find university by domain
        let universities: [University] = try await supabase
            .from("universities")
            .select()
            .eq("email_domain", value: domain)
            .execute()
            .value
        
        guard let university = universities.first else {
            throw UniversityError.universityNotFound
        }
        
        // Send verification email via Supabase Auth
        try await supabase.auth.update(user: .init(email: email))
        
        // Update profile with pending verification
        try await supabase
            .from("profiles")
            .update([
                "university_id": university.id.uuidString,
                "university_email": email,
                "is_university_verified": false
            ])
            .eq("id", value: userId.uuidString)
            .execute()
        
        await AuthService.shared.loadCurrentProfile()
    }
    
    // MARK: - Verify University Email
    
    func verifyUniversityEmail() async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        try await supabase
            .from("profiles")
            .update(["is_university_verified": true])
            .eq("id", value: userId.uuidString)
            .execute()
        
        await AuthService.shared.loadCurrentProfile()
    }
    
    // MARK: - Get University Leaderboard
    
    func fetchUniversityLeaderboard(universityId: UUID) async throws -> UniversityLeaderboard {
        let university: University = try await supabase
            .from("universities")
            .select()
            .eq("id", value: universityId.uuidString)
            .single()
            .execute()
            .value
        
        // Get all verified members with handicaps
        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("university_id", value: universityId.uuidString)
            .eq("is_university_verified", value: true)
            .not("handicap", operator: .is, value: "null")
            .order("handicap", ascending: true)
            .execute()
            .value
        
        let rankings = profiles.enumerated().map { index, profile in
            UniversityRanking(
                userId: profile.id,
                universityId: universityId,
                rank: index + 1,
                handicap: profile.handicap ?? 0,
                user: profile,
                university: university
            )
        }
        
        currentUniversityRankings = rankings
        
        // Find current user's rank
        if let currentUserId = AuthService.shared.currentUser?.id {
            userRank = rankings.firstIndex(where: { $0.userId == currentUserId }).map { $0 + 1 }
        }
        
        let avgHandicap = profiles.compactMap { $0.handicap }.reduce(0, +) / Double(max(1, profiles.count))
        
        return UniversityLeaderboard(
            university: university,
            rankings: rankings,
            totalMembers: profiles.count,
            averageHandicap: profiles.isEmpty ? nil : avgHandicap
        )
    }
    
    // MARK: - Get User's University Rank Badge
    
    func fetchUserRankBadge(userId: UUID) async throws -> UniversityRankBadge? {
        guard let profile = try? await supabase
            .from("profiles")
            .select("*, university:universities(*)")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value as Profile,
              profile.isUniversityVerified,
              let university = profile.university,
              let handicap = profile.handicap else {
            return nil
        }
        
        // Get rank
        let betterPlayers: [Profile] = try await supabase
            .from("profiles")
            .select("id")
            .eq("university_id", value: university.id.uuidString)
            .eq("is_university_verified", value: true)
            .lt("handicap", value: handicap)
            .execute()
            .value
        
        let rank = betterPlayers.count + 1
        
        return UniversityRankBadge(
            university: university,
            rank: rank,
            handicap: handicap
        )
    }
}

struct UniversityRankBadge {
    let university: University
    let rank: Int
    let handicap: Double
    
    var rankDisplay: String { "#\(rank)" }
}

enum UniversityError: LocalizedError {
    case invalidEmail, universityNotFound, verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Invalid email format."
        case .universityNotFound: return "University not found for this email domain."
        case .verificationFailed: return "Email verification failed."
        }
    }
}