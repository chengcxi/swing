import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var showMenu: Bool = false
    @Published var showFriendFinder: Bool = false
    @Published var showCreatePost: Bool = false
    @Published var selectedCourse: GolfCourse?
    @Published var currentUser: User?

    init() {
        // Simulate checking auth status
        self.isAuthenticated = true
        self.currentUser = User(
            id: "1",
            name: "John",
            username: "@johndoe",
            avatar: "https://via.placeholder.com/150",
            isVerified: true,
            isPro: false,
            description: "Golfer | Developer",
            favoriteCourse: "Pebble Beach",
            university: "Stanford",
            handicap: 12.5
        )
    }

    func login() {
        isAuthenticated = true
    }

    func logout() {
        isAuthenticated = false
    }
    
    // MARK: - University Verification
    func verifyEmail(_ email: String) {
        guard email.hasSuffix(".edu") else { return }
        // Mock verification success
        if var user = currentUser {
            let schoolName = email.components(separatedBy: "@").last?.components(separatedBy: ".").first?.capitalized ?? "University"
            let badge = Badge(id: "uni_verified", name: "Verified Student", icon: "checkmark.seal.fill", description: "Verified student at \(schoolName)", dateEarned: Date())
            
            // Update User
            // In a real app, this would be an API call
            // We are mocking immutable struct update by creating a new one (SwiftUI state)
             currentUser = User(
                id: user.id,
                name: user.name,
                username: user.username,
                avatar: user.avatar,
                isVerified: true, // Mark as verified
                isPro: user.isPro,
                description: user.description,
                favoriteCourse: user.favoriteCourse,
                university: schoolName, // Set University Name
                eduEmail: email,
                handicap: user.handicap,
                badges: user.badges + [badge],
                playingStreak: user.playingStreak,
                universityRank: calculateMockRank(for: user.handicap),
                schoolId: "univ_123"
            )
        }
    }
    
    private func calculateMockRank(for handicap: Double?) -> Int? {
        guard let handicap = handicap else { return nil }
        // Mock logic: if handicap < 5, they are top 10.
        if handicap < 5.0 {
            return Int.random(in: 1...10)
        }
        return nil
    }
}
