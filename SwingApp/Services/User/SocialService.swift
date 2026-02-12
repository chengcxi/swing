import Foundation

@MainActor
class SocialService: ObservableObject {
    static let shared = SocialService()
    
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Follow Operations
    
    func followUser(userId: UUID) async throws {
        guard let currentUserId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        guard currentUserId != userId else {
            throw SocialError.cannotFollowSelf
        }
        
        let follow = [
            "follower_id": currentUserId.uuidString,
            "following_id": userId.uuidString
        ]
        
        try await supabase
            .from("follows")
            .insert(follow)
            .execute()
    }
    
    func unfollowUser(userId: UUID) async throws {
        guard let currentUserId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: currentUserId.uuidString)
            .eq("following_id", value: userId.uuidString)
            .execute()
    }
    
    func isFollowing(userId: UUID) async throws -> Bool {
        guard let currentUserId = AuthService.shared.currentUser?.id else {
            return false
        }
        
        let follows: [Follow] = try await supabase
            .from("follows")
            .select("follower_id, following_id, created_at")
            .eq("follower_id", value: currentUserId.uuidString)
            .eq("following_id", value: userId.uuidString)
            .execute()
            .value
        
        return !follows.isEmpty
    }
    
    func fetchFollowers(userId: UUID) async throws -> [Profile] {
        let follows: [Follow] = try await supabase
            .from("follows")
            .select("follower:profiles!follows_follower_id_fkey(*)")
            .eq("following_id", value: userId.uuidString)
            .execute()
            .value
        
        return follows.compactMap { $0.follower }
    }
    
    func fetchFollowing(userId: UUID) async throws -> [Profile] {
        let follows: [Follow] = try await supabase
            .from("follows")
            .select("following:profiles!follows_following_id_fkey(*)")
            .eq("follower_id", value: userId.uuidString)
            .execute()
            .value
        
        return follows.compactMap { $0.following }
    }
    
    func fetchFollowCounts(userId: UUID) async throws -> FollowCounts {
        async let followers: [Follow] = supabase
            .from("follows")
            .select("follower_id, following_id, created_at")
            .eq("following_id", value: userId.uuidString)
            .execute()
            .value
        
        async let following: [Follow] = supabase
            .from("follows")
            .select("follower_id, following_id, created_at")
            .eq("follower_id", value: userId.uuidString)
            .execute()
            .value
        
        let (followersResult, followingResult) = try await (followers, following)
        
        return FollowCounts(
            followers: followersResult.count,
            following: followingResult.count
        )
    }
    
    // MARK: - Like Operations
    
    func likeRound(roundId: UUID) async throws {
        guard let currentUserId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        let like = [
            "user_id": currentUserId.uuidString,
            "round_id": roundId.uuidString
        ]
        
        try await supabase
            .from("likes")
            .insert(like)
            .execute()
    }
    
    func unlikeRound(roundId: UUID) async throws {
        guard let currentUserId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        try await supabase
            .from("likes")
            .delete()
            .eq("user_id", value: currentUserId.uuidString)
            .eq("round_id", value: roundId.uuidString)
            .execute()
    }
    
    func hasLikedRound(roundId: UUID) async throws -> Bool {
        guard let currentUserId = AuthService.shared.currentUser?.id else {
            return false
        }
        
        let likes: [Like] = try await supabase
            .from("likes")
            .select("user_id, round_id, created_at")
            .eq("user_id", value: currentUserId.uuidString)
            .eq("round_id", value: roundId.uuidString)
            .execute()
            .value
        
        return !likes.isEmpty
    }
    
    func fetchLikesCount(roundId: UUID) async throws -> Int {
        let likes: [Like] = try await supabase
            .from("likes")
            .select("user_id, round_id, created_at")
            .eq("round_id", value: roundId.uuidString)
            .execute()
            .value
        
        return likes.count
    }
    
    // MARK: - Comment Operations
    
    func addComment(roundId: UUID, content: String) async throws -> Comment {
        guard let currentUserId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        let commentInsert = CommentInsert(
            userId: currentUserId,
            roundId: roundId,
            content: content
        )
        
        let comment: Comment = try await supabase
            .from("comments")
            .insert(commentInsert)
            .select("*, user:profiles(*)")
            .single()
            .execute()
            .value
        
        return comment
    }
    
    func fetchComments(roundId: UUID) async throws -> [Comment] {
        let comments: [Comment] = try await supabase
            .from("comments")
            .select("*, user:profiles(*)")
            .eq("round_id", value: roundId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return comments
    }
    
    func deleteComment(id: UUID) async throws {
        try await supabase
            .from("comments")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - User Search
    
    func searchUsers(query: String) async throws -> [Profile] {
        guard !query.isEmpty else { return [] }
        
        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select()
            .or("username.ilike.%\(query)%,full_name.ilike.%\(query)%")
            .limit(20)
            .execute()
            .value
        
        return profiles
    }
    
    func fetchProfile(userId: UUID) async throws -> Profile {
        let profile: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        return profile
    }
}

// MARK: - Social Errors
enum SocialError: LocalizedError {
    case cannotFollowSelf
    
    var errorDescription: String? {
        switch self {
        case .cannotFollowSelf:
            return "You cannot follow yourself."
        }
    }
}
