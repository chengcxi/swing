import Foundation
import Combine
import Supabase

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String?

    // Set to true to bypass Supabase auth and use mock data for UI development.
    // While this is on, all backend writes (saveRound, addFriend, etc.) become
    // local-only no-ops so the UI is usable without a real auth session.
    let devMode = false

    // In-memory dev-mode stores
    private var devRounds: [Round] = []
    private var devFavorites: [Course] = []
    private var devFollowingIds: Set<UUID> = []

    private var authListener: Task<Void, Never>?

    init() {
        if devMode {
            currentUser = User.mock
            isAuthenticated = true
            return
        }
        // Check for existing session
        Task {
            await checkSession()
        }
        listenForAuthChanges()
    }

    deinit {
        authListener?.cancel()
    }

    // MARK: - Auth

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            if let email = session.user.email {
                try? await ensureProfileExists(userId: session.user.id, email: email)
            }
            await loadProfile(userId: session.user.id)
            isAuthenticated = true
        } catch {
            // No active session — stay on login
            isAuthenticated = false
        }
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        authError = nil
        do {
            let response = try await supabase.auth.signUp(email: email, password: password)

            // RLS requires an active session (auth.uid() = id) for the profiles insert
            // to succeed. If Supabase is configured for email confirmation, there's no
            // session yet — defer the profile creation to first sign-in.
            let hasSession = (try? await supabase.auth.session) != nil
            if hasSession {
                try await ensureProfileExists(userId: response.user.id, email: email)
                await loadProfile(userId: response.user.id)
                isAuthenticated = true
            } else {
                authError = "Check your email to confirm your account, then sign in."
            }
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    /// Insert a profile row if one doesn't already exist for this user.
    /// Idempotent — safe to call on every sign-in.
    private func ensureProfileExists(userId: UUID, email: String) async throws {
        // Already exists?
        let existing: [DBProfile] = (try? await supabase.from("profiles")
            .select("id")
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value) ?? []
        if !existing.isEmpty { return }

        let profile = InsertProfile(
            id: userId,
            username: generateUsername(from: email),
            fullName: nil
        )
        try await supabase.from("profiles")
            .insert(profile)
            .execute()
    }

    /// Generate a username that satisfies the schema's regex and length constraints.
    private func generateUsername(from email: String) -> String {
        let local = email.components(separatedBy: "@").first ?? "user"
        let cleaned = local.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
        let base = cleaned.isEmpty ? "user" : String(cleaned.prefix(20))
        let suffix = String(UUID().uuidString.prefix(6)).lowercased().filter { $0.isLetter || $0.isNumber }
        let combined = "\(base)_\(suffix)"
        return String(combined.prefix(30))
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        authError = nil
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            // First sign-in after email confirmation needs a profile row created.
            try? await ensureProfileExists(userId: session.user.id, email: email)
            await loadProfile(userId: session.user.id)
            isAuthenticated = true
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            // Ignore sign-out errors
        }
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Profile

    func loadProfile(userId: UUID) async {
        do {
            let profile: DBProfile = try await supabase.from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            // Fetch follower count
            let followers: [DBFollow] = try await supabase.from("follows")
                .select()
                .eq("following_id", value: userId)
                .execute()
                .value

            // Fetch rounds for stats
            let rounds: [DBRound] = try await supabase.from("rounds")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            // Fetch university name if linked
            var universityName: String?
            if let uniId = profile.universityId {
                let uni: DBUniversity = try await supabase.from("universities")
                    .select()
                    .eq("id", value: uniId)
                    .single()
                    .execute()
                    .value
                universityName = uni.shortName ?? uni.name
            }

            let scores = rounds.map { $0.score }
            let avgScore = scores.isEmpty ? 0.0 : Double(scores.reduce(0, +)) / Double(scores.count)
            let bestRound = scores.min() ?? 0

            currentUser = User(
                id: profile.id,
                username: profile.username,
                fullName: profile.fullName ?? profile.username,
                isVerified: profile.isUniversityVerified ?? false,
                profileImageName: profile.avatarUrl ?? "",
                university: universityName,
                handicap: profile.handicap ?? 0.0,
                averageScore: avgScore,
                bestRound: bestRound,
                roundsPlayed: rounds.count,
                badges: profile.isUniversityVerified == true ? [.verified] : [],
                bio: profile.bio,
                friendsCount: followers.count
            )
        } catch {
            print("🚨 loadProfile failed for userId \(userId): \(error)")
            print("🚨 Full error: \(String(reflecting: error))")
        }
    }

    func updateProfile(fullName: String, username: String, bio: String, university: String?) {
        guard let userId = currentUser?.id else { return }

        // Update local state immediately
        if var user = currentUser {
            user.fullName = fullName
            user.username = username
            user.bio = bio.isEmpty ? nil : bio
            self.currentUser = user
        }

        // Push to Supabase
        Task {
            let update = UpdateProfile(
                username: username,
                fullName: fullName,
                bio: bio.isEmpty ? nil : bio,
                avatarUrl: nil,
                handicap: nil
            )
            do {
                try await supabase.from("profiles")
                    .update(update)
                    .eq("id", value: userId)
                    .execute()
            } catch {
                print("Failed to update profile: \(error)")
            }
        }
    }

    // MARK: - Rounds

    func fetchRounds() async -> [Round] {
        if devMode { return devRounds }
        guard let userId = currentUser?.id else { return [] }
        do {
            let dbRounds: [DBRound] = try await supabase.from("rounds")
                .select("*, course:golf_courses(*)")
                .eq("user_id", value: userId)
                .order("date_played", ascending: false)
                .execute()
                .value

            return dbRounds.map { dbRound in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: dbRound.datePlayed) ?? Date()

                return Round(
                    id: dbRound.id,
                    courseId: dbRound.courseId ?? UUID(),
                    courseName: dbRound.course?.name ?? "Unknown Course",
                    location: [dbRound.course?.city, dbRound.course?.state]
                        .compactMap { $0 }
                        .joined(separator: ", "),
                    score: dbRound.score,
                    date: date,
                    holes: dbRound.course?.holes ?? 18
                )
            }
        } catch {
            print("Failed to fetch rounds: \(error)")
            return []
        }
    }

    /// Finds an existing course in Supabase or inserts a new one. Returns its Supabase UUID.
    /// Prefers Google Place ID for dedupe (schema enforces UNIQUE), falls back to name+city.
    func findOrCreateCourse(from course: Course) async -> UUID? {
        if devMode {
            // In dev mode the Course's own UUID is the only ID we need.
            return course.id
        }
        // 1. Dedupe by Google Place ID first (schema's UNIQUE constraint)
        if let placeId = course.googlePlaceId {
            let matches: [DBGolfCourse] = (try? await supabase.from("golf_courses")
                .select()
                .eq("google_place_id", value: placeId)
                .limit(1)
                .execute()
                .value) ?? []
            if let match = matches.first {
                return match.id
            }
        }

        // 2. Fall back to name+city match
        do {
            var query = supabase.from("golf_courses")
                .select()
                .ilike("name", pattern: course.name)
            if let city = course.city, !city.isEmpty {
                query = query.eq("city", value: city)
            }
            let candidates: [DBGolfCourse] = try await query
                .limit(1)
                .execute()
                .value
            if let match = candidates.first {
                return match.id
            }
        } catch {
            print("findOrCreateCourse lookup failed: \(error)")
        }

        // 3. Insert. Use real lat/lng when available; otherwise schema requires non-null
        //    so fall back to 0,0. City is also non-null — fall back to name as a last resort.
        struct CourseInsert: Encodable {
            let name: String
            let address: String
            let city: String
            let state: String?
            let country: String
            let latitude: Double
            let longitude: Double
            let holes: Int
            let par: Int
            let google_place_id: String?
        }

        let resolvedCity: String = {
            if let c = course.city, !c.isEmpty { return c }
            return course.location.components(separatedBy: ",")
                .dropFirst()
                .first?
                .trimmingCharacters(in: .whitespaces) ?? course.name
        }()

        let insert = CourseInsert(
            name: course.name,
            address: course.location,
            city: resolvedCity,
            state: course.state,
            country: "USA",
            latitude: course.latitude ?? 0,
            longitude: course.longitude ?? 0,
            holes: 18,
            par: 72,
            google_place_id: course.googlePlaceId
        )

        do {
            let created: DBGolfCourse = try await supabase.from("golf_courses")
                .insert(insert)
                .select()
                .single()
                .execute()
                .value
            return created.id
        } catch {
            print("findOrCreateCourse insert failed: \(error)")
            return nil
        }
    }

    func saveRound(course: Course?, courseId: UUID?, score: Int, date: Date, notes: String?, holeScores: [HoleScoreEntry]) async -> Bool {
        if devMode {
            let round = Round(
                id: UUID(),
                courseId: courseId ?? UUID(),
                courseName: course?.name ?? "Unknown Course",
                location: course?.location ?? "",
                score: score,
                date: date,
                holes: 18
            )
            devRounds.insert(round, at: 0)
            // Keep stats fresh on the mock user too
            if var user = currentUser {
                user.roundsPlayed = devRounds.count
                let scores = devRounds.map { $0.score }
                user.bestRound = scores.min() ?? 0
                user.averageScore = scores.isEmpty ? 0.0 : Double(scores.reduce(0, +)) / Double(scores.count)
                currentUser = user
            }
            return true
        }

        guard let userId = currentUser?.id else {
            print("⚠️ saveRound: no currentUser.id")
            return false
        }

        // Debug: confirm what Supabase thinks our session is right now
        do {
            let session = try await supabase.auth.session
            print("🔐 saveRound session — auth.uid: \(session.user.id), email: \(session.user.email ?? "nil"), confirmed_at: \(String(describing: session.user.emailConfirmedAt))")
            print("🆔 currentUser.id (used for insert): \(userId)")
            if session.user.id != userId {
                print("🚨 MISMATCH: session.user.id != currentUser.id — that's the bug")
            }
        } catch {
            print("🚨 saveRound: NO ACTIVE SESSION — \(error). RLS will reject any insert.")
            return false
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let insert = InsertRound(
            userId: userId,
            courseId: courseId,
            score: score,
            datePlayed: dateFormatter.string(from: date),
            notes: notes
        )

        do {
            let result: DBRound = try await supabase.from("rounds")
                .insert(insert)
                .select()
                .single()
                .execute()
                .value

            // Insert hole scores
            if !holeScores.isEmpty {
                let holeInserts = holeScores.map { hole in
                    InsertHoleScore(
                        roundId: result.id,
                        holeNumber: hole.holeNumber,
                        par: hole.par,
                        score: hole.score
                    )
                }
                try await supabase.from("hole_scores")
                    .insert(holeInserts)
                    .execute()
            }

            // Reload profile to update stats
            await loadProfile(userId: userId)
            return true
        } catch {
            print("🚨 saveRound failed: \(error)")
            print("🚨 Full error: \(String(reflecting: error))")
            return false
        }
    }

    // MARK: - Favorite Courses (Rankings)

    func fetchFavoriteCourses() async -> [Course] {
        if devMode { return devFavorites }
        guard let userId = currentUser?.id else { return [] }
        do {
            let favs: [DBFavoriteCourse] = try await supabase.from("favorite_courses")
                .select("*, course:golf_courses(*)")
                .eq("user_id", value: userId)
                .order("rank")
                .execute()
                .value
            return favs.compactMap { fav -> Course? in
                guard let dbCourse = fav.course else { return nil }
                let loc = [dbCourse.city, dbCourse.state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                return Course(
                    id: dbCourse.id,
                    name: dbCourse.name,
                    location: loc.isEmpty ? dbCourse.address : loc,
                    // holes: dbCourse.holes ?? 18,
                    // par: dbCourse.par ?? 72,
                    // difficulty: dbCourse.courseRating ?? 0,
                    // hasDrivingRange: false,
                    // hasPuttingGreen: false,
                    // latitude: dbCourse.latitude,
                    // longitude: dbCourse.longitude,
                    // googlePlaceId: dbCourse.googlePlaceId,
                    // city: dbCourse.city,
                    // state: dbCourse.state
                )
            }
        } catch {
            print("AppViewModel.fetchFavoriteCourses failed: \(error)")
            return []
        }
    }

    func saveFavoriteCoursesOrder(_ courses: [Course]) async {
        if devMode {
            devFavorites = courses
            return
        }
        guard let userId = currentUser?.id else { return }
        do {
            // Replace existing rankings: delete all, then insert in order.
            try await supabase.from("favorite_courses")
                .delete()
                .eq("user_id", value: userId)
                .execute()

            struct FavInsert: Encodable {
                let user_id: UUID
                let course_id: UUID
                let rank: Int
            }
            let inserts = courses.enumerated().map { index, course in
                FavInsert(user_id: userId, course_id: course.id, rank: index + 1)
            }
            if !inserts.isEmpty {
                try await supabase.from("favorite_courses")
                    .insert(inserts)
                    .execute()
            }
        } catch {
            print("AppViewModel.saveFavoriteCoursesOrder failed: \(error)")
        }
    }

    func addFavoriteCourse(_ course: Course) async {
        if devMode {
            if !devFavorites.contains(where: { $0.id == course.id }) {
                devFavorites.append(course)
            }
            return
        }
        guard let userId = currentUser?.id else { return }
        do {
            // Resolve to a real Supabase course id (in case it came from Places)
            guard let supabaseCourseId = await findOrCreateCourse(from: course) else { return }

            // Determine next rank
            let existing: [DBFavoriteCourse] = (try? await supabase.from("favorite_courses")
                .select("rank")
                .eq("user_id", value: userId)
                .order("rank", ascending: false)
                .limit(1)
                .execute()
                .value) ?? []
            let nextRank = (existing.first?.rank ?? 0) + 1

            struct FavInsert: Encodable {
                let user_id: UUID
                let course_id: UUID
                let rank: Int
            }
            try await supabase.from("favorite_courses")
                .insert(FavInsert(user_id: userId, course_id: supabaseCourseId, rank: nextRank))
                .execute()
        } catch {
            print("AppViewModel.addFavoriteCourse failed: \(error)")
        }
    }

    func removeFavoriteCourse(courseId: UUID) async {
        if devMode {
            devFavorites.removeAll { $0.id == courseId }
            return
        }
        guard let userId = currentUser?.id else { return }
        do {
            try await supabase.from("favorite_courses")
                .delete()
                .eq("user_id", value: userId)
                .eq("course_id", value: courseId)
                .execute()
        } catch {
            print("AppViewModel.removeFavoriteCourse failed: \(error)")
        }
    }

    // MARK: - Friends & Search
    
    func searchUsers(query: String) async -> [User] {
        if query.isEmpty { return [] }
        do {
            let limitQuery = "%\(query)%"
            let profiles: [DBProfile] = try await supabase.from("profiles")
                .select()
                .or("username.ilike.\(limitQuery),full_name.ilike.\(limitQuery)")
                .limit(20)
                .execute()
                .value

            return profiles.map { profile in
                User(
                    id: profile.id,
                    username: profile.username,
                    fullName: profile.fullName ?? profile.username,
                    isVerified: profile.isUniversityVerified ?? false,
                    profileImageName: profile.avatarUrl ?? "profile_placeholder",
                    university: nil,
                    handicap: profile.handicap ?? 0.0,
                    averageScore: 0.0,
                    bestRound: 0,
                    roundsPlayed: 0,
                    badges: profile.isUniversityVerified == true ? [.verified] : [],
                    bio: profile.bio,
                    friendsCount: 0
                )
            }
        } catch {
            print("Failed to search users: \(error)")
            return []
        }
    }

    /// Dev-mode-only: are we following this user (in-memory)?
    func isFollowingDev(_ userId: UUID) -> Bool {
        devFollowingIds.contains(userId)
    }

    /// Dev-mode-only: toggle follow state (in-memory).
    func toggleFollowDev(_ userId: UUID) {
        if devFollowingIds.contains(userId) {
            devFollowingIds.remove(userId)
        } else {
            devFollowingIds.insert(userId)
        }
        if var user = currentUser {
            user.friendsCount = devFollowingIds.count
            currentUser = user
        }
    }

    func addFriend(userId: UUID) async {
        if devMode {
            devFollowingIds.insert(userId)
            if var user = currentUser {
                user.friendsCount = devFollowingIds.count
                currentUser = user
            }
            return
        }
        guard let currentId = currentUser?.id else { return }
        let follow = DBFollow(followerId: currentId, followingId: userId)
        do {
            try await supabase.from("follows")
                .insert(follow)
                .execute()
            
            // Optionally update locally
            if var user = currentUser {
                user.friendsCount += 1
                self.currentUser = user
            }
        } catch {
            print("Failed to follow user: \(error)")
        }
    }

    // MARK: - Auth Listener

    private func listenForAuthChanges() {
        authListener = Task {
            for await (event, session) in supabase.auth.authStateChanges {
                guard !Task.isCancelled else { return }
                switch event {
                case .signedIn:
                    if let session {
                        await loadProfile(userId: session.user.id)
                        isAuthenticated = true
                    }
                case .signedOut:
                    currentUser = nil
                    isAuthenticated = false
                default:
                    break
                }
            }
        }
    }

    func verifyUniversityEmail(email: String) {
        guard email.hasSuffix(".edu") else { return }

        if var user = currentUser {
            user.university = "University of Example"
            user.isVerified = true
            user.badges.append(.verified)
            self.currentUser = user
        }
    }
}
