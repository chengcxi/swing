import Foundation
import Combine
import Supabase

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String?

    private var authListener: Task<Void, Never>?

    init() {
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
            // Create a profile row for the new user
            let profile = UpdateProfile(
                username: email.components(separatedBy: "@").first ?? "user",
                fullName: nil,
                bio: nil,
                avatarUrl: nil,
                handicap: nil
            )
            try await supabase.from("profiles")
                .insert(profile)
                .execute()

            await loadProfile(userId: response.user.id)
            isAuthenticated = true
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        authError = nil
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
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
            print("Failed to load profile: \(error)")
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

    func saveRound(courseId: UUID?, score: Int, date: Date, notes: String?, holeScores: [HoleScoreEntry]) async -> Bool {
        guard let userId = currentUser?.id else { return false }

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
            print("Failed to save round: \(error)")
            return false
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
