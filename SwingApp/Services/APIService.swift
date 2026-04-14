import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

class APIService {
    static let shared = APIService()
    private let baseURL = "https://api.swingapp.com/v1" // Placeholder URL
    
    private init() {}
    
    func fetchPosts() -> AnyPublisher<[Post], APIError> {
        return Future<[Post], APIError> { promise in
            Task {
                do {
                    // Fetch latest rounds
                    let dbRounds: [DBRound] = try await supabase.from("rounds")
                        .select("*, course:golf_courses(*)")
                        .order("date_played", ascending: false)
                        .limit(20)
                        .execute()
                        .value
                    
                    var posts = [Post]()
                    for dbRound in dbRounds {
                        // Fetch profile for the round
                        let profile: DBProfile? = try? await supabase.from("profiles")
                            .select()
                            .eq("id", value: dbRound.userId)
                            .single()
                            .execute()
                            .value
                        
                        let user = User(
                            id: profile?.id ?? dbRound.userId,
                            username: profile?.username ?? "Unknown",
                            fullName: profile?.fullName ?? "Unknown",
                            isVerified: profile?.isUniversityVerified ?? false,
                            profileImageName: profile?.avatarUrl ?? "",
                            university: nil,
                            handicap: profile?.handicap ?? 0.0,
                            averageScore: 0.0,
                            bestRound: 0,
                            roundsPlayed: 0,
                            badges: [],
                            bio: profile?.bio,
                            friendsCount: 0
                        )
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let datePlayed = dateFormatter.date(from: dbRound.datePlayed) ?? Date()
                        
                        let round = Round(
                            id: dbRound.id,
                            courseId: dbRound.courseId ?? UUID(),
                            courseName: dbRound.course?.name ?? "Golf Course",
                            location: dbRound.course?.city ?? "",
                            score: dbRound.score,
                            date: datePlayed,
                            holes: dbRound.course?.holes ?? 18
                        )
                        
                        let post = Post(
                            id: dbRound.id, // Using round ID as post ID for likes
                            user: user,
                            round: round,
                            caption: dbRound.notes ?? "Played a great round!",
                            timestamp: datePlayed,
                            likes: 0, // Mocking counts for now
                            comments: 0,
                            isLiked: false
                        )
                        posts.append(post)
                    }
                    
                    DispatchQueue.main.async {
                        promise(.success(posts))
                    }
                } catch {
                    DispatchQueue.main.async {
                        promise(.failure(.networkError(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchUser(id: UUID) -> AnyPublisher<User, APIError> {
        return Future<User, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                promise(.success(User.mock))
            }
        }
        .eraseToAnyPublisher()
    }
}
