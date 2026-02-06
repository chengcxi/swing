import Foundation
import Supabase

class DataService {
    static let shared = DataService()
    
    private init() {}
    
    // MARK: - Posts
    
    func fetchPosts() async throws -> [Post] {
        let response: [Post] = try await supabase
            .from("posts")
            .select("""
                *,
                profiles:user_id(*),
                rounds:round_id(*)
            """)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func createPost(caption: String, roundId: UUID?, imagePath: String?) async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }
        
        struct NewPost: Encodable {
            let user_id: UUID
            let round_id: UUID?
            let caption: String
            let image_url: String?
        }
        
        let newPost = NewPost(user_id: userId, round_id: roundId, caption: caption, image_url: imagePath)
        
        try await supabase.from("posts").insert(newPost).execute()
    }
    
    // MARK: - Rounds
    
    func fetchRounds(for userId: UUID) async throws -> [Round] {
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value
        
        return rounds
    }
    
    func createRound(_ round: Round) async throws {
        // We need to encode the round but make sure we respect the table columns.
        // Since Round is Codable, we can try inserting it directly if it matches exactly,
        // excluding ID if we want auto-gen, but our struct has ID.
        // Better to create a transient struct or ensure ID is handled.
        // Assuming the client generates ID or we let backend do it.
        // If we let backend do it, we shouldn't send ID.
        
        struct NewRound: Encodable {
            let user_id: UUID
            let course_id: UUID?
            let course_name: String?
            let location: String?
            let score: Int
            let date: Date
            let holes: Int
        }
        
        guard let userId = supabase.auth.currentUser?.id else { return }

        let newRound = NewRound(
            user_id: userId,
            course_id: round.courseId,
            course_name: round.courseName,
            location: round.location,
            score: round.score,
            date: round.date,
            holes: round.holes
        )
        
        try await supabase.from("rounds").insert(newRound).execute()
    }
    
    // MARK: - Courses
    
    func fetchCourses(search: String = "") async throws -> [Course] {
        var query = supabase.from("courses").select()
        
        if !search.isEmpty {
            query = query.ilike("name", pattern: "%\(search)%")
        }
        
        var courses: [Course] = try await query.limit(20).execute().value
        
        // If we have search text but few/no results, try Google
        if !search.isEmpty && courses.count < 5 {
            do {
                let googleResults = try await GoogleService.shared.searchGolfCourses(query: search)
                
                // Convert Google results to Course objects (temporary ones for UI)
                // Filter out ones we already have by checking place_id or rough name match if needed
                // For now, just append unique ones.
                
                let existingPlaceIds = Set(courses.compactMap { $0.googlePlaceId })
                
                for place in googleResults {
                    if !existingPlaceIds.contains(place.placeId) {
                        // Create a transient Course object
                        let googleCourse = Course(
                            id: UUID(), // Temporary UUID
                            name: place.mainText,
                            location: place.secondaryText,
                            holes: 18, // Default, will update on import
                            difficulty: nil,
                            hasDrivingRange: false,
                            hasPuttingGreen: false,
                            latitude: nil, // fetch details on selection
                            longitude: nil, // fetch details on selection
                            googlePlaceId: place.placeId
                        )
                        courses.append(googleCourse)
                    }
                }
            } catch {
                print("Google Search Error: \(error)")
            }
        }
        
        return courses
    }
    
    func importGoogleCourse(course: Course) async throws -> Course {
        guard let placeId = course.googlePlaceId else { return course }
        
        // 1. Fetch full details from Google
        let details = try await GoogleService.shared.getPlaceDetails(placeId: placeId)
        
        // 2. Check if it already exists in DB (by place_id) to avoid duplicates
        // (The UI might have triggered this, but multiple users race condition)
        let existing: [Course] = try await supabase.from("courses").select().eq("google_place_id", value: placeId).execute().value
        if let first = existing.first {
            return first
        }
        
        // 3. Insert new course
        struct NewCourse: Encodable, Decodable {
            let id: UUID? // Optional for insert return
            let name: String
            let location: String?
            let latitude: Double
            let longitude: Double
            let google_place_id: String
            let holes: Int
        }
        
        let newCourseData = NewCourse(
            id: nil,
            name: details.name,
            location: details.address,
            latitude: details.latitude,
            longitude: details.longitude,
            google_place_id: placeId,
            holes: 18 // Default
        )
        
        let savedCourse: Course = try await supabase
            .from("courses")
            .insert(newCourseData)
            .select()
            .single()
            .execute()
            .value
            
        return savedCourse
    }
    
    // MARK: - Interactions
    
    func likePost(postId: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }
        
        struct NewLike: Encodable {
            let post_id: UUID
            let user_id: UUID
        }
        
        let like = NewLike(post_id: postId, user_id: userId)
        try await supabase.from("likes").insert(like).execute()
    }
    
    func unlikePost(postId: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }
        
        try await supabase.from("likes")
            .delete()
            .match(["post_id": postId, "user_id": userId])
            .execute()
    }
    
    func addComment(postId: UUID, text: String) async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }
        
        struct NewComment: Encodable {
            let post_id: UUID
            let user_id: UUID
            let text: String
        }
        
        let comment = NewComment(post_id: postId, user_id: userId, text: text)
        try await supabase.from("comments").insert(comment).execute()
    }

    // MARK: - Friends & Users
    
    func searchUsers(query: String) async throws -> [User] {
        guard !query.isEmpty else { return [] }
        
        let users: [User] = try await supabase
            .from("profiles")
            .select()
            .ilike("username", pattern: "%\(query)%") // Search by username
            .limit(20)
            .execute()
            .value
        
        return users
    }
    
    func followUser(targetId: UUID) async throws {
        guard let currentUserId = supabase.auth.currentUser?.id else { return }
        
        struct NewFriendship: Encodable {
            let follower_id: UUID
            let following_id: UUID
            let status: String
        }
        
        // Auto-accept for now or 'pending' if we want requests. 
        // Logic says 'default pending' in schema, but let's send 'accepted' if we want instant follow 
        // OR better, let it be pending and have an accept function.
        // For simple 'Follow', usually it's instant or pending. 
        // Let's assume 'accepted' for now for simplicity of the "Friends" button just working, 
        // unless I implement the Accept flow.
        // The Schema check constraint allows 'pending' or 'accepted'.
        let friendship = NewFriendship(follower_id: currentUserId, following_id: targetId, status: "accepted")
        
        try await supabase.from("friendships").insert(friendship).execute()
    }
    
    func unfollowUser(targetId: UUID) async throws {
        guard let currentUserId = supabase.auth.currentUser?.id else { return }
        
        try await supabase.from("friendships")
            .delete()
            .match(["follower_id": currentUserId, "following_id": targetId])
            .execute()
    }
    
    func checkFriendshipStatus(targetId: UUID) async throws -> String? {
        guard let currentUserId = supabase.auth.currentUser?.id else { return nil }
        
        struct Friendship: Decodable {
            let status: String
        }
        
        // Check if I follow them
        let response: [Friendship] = try await supabase
            .from("friendships")
            .select("status")
            .match(["follower_id": currentUserId, "following_id": targetId])
            .execute()
            .value
            
        return response.first?.status
    }
}
