import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    init() {
        // Simulate loading user
        self.currentUser = User.mock
        self.isAuthenticated = true
    }
    
    func verifyUniversityEmail(email: String) {
        // Mock verification logic
        guard email.hasSuffix(".edu") else { return }
        
        if var user = currentUser {
            user.university = "University of Example"
            user.isVerified = true
            user.badges.append(.verified)
            self.currentUser = user
        }
    }
}
