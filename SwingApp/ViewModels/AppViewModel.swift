import Foundation
import Combine
import Supabase

class AppViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        AuthService.shared.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = (user != nil)
            }
            .store(in: &cancellables)
    }
    
    func verifyUniversityEmail(email: String) {
        // This logis would ideally move to a Cloud Function or backend logic
        // For now, we update the local model but it won't persist to DB unless we call a service.
        guard email.hasSuffix(".edu") else { return }
        
        // TODO: Call API to update verification status
    }
}
