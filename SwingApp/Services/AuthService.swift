import Foundation
import Supabase

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var session: Session?
    @Published var user: User?
    
    private init() {
        // Listen for auth changes
        Task {
            for await _ in supabase.auth.authStateChanges {
                self.session = try? await supabase.auth.session
                if let userId = session?.user.id {
                    await fetchProfile(userId: userId)
                } else {
                    self.user = nil
                }
            }
        }
    }
    
    func signUp(email: String, password: String, username: String) async throws {
        _ = try await supabase.auth.signUp(
            email: email,
            password: password, 
            data: ["username": .string(username)]
        )
        )
        // Profile creation is handled by the `handle_new_user` trigger in Supabase.
    }
    
    func signIn(email: String, password: String) async throws {
        _ = try await supabase.auth.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    func fetchProfile(userId: UUID) async {
        do {
            let profile: User = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            DispatchQueue.main.async {
                self.user = profile
            }
        } catch {
            print("Error fetching profile: \(error)")
        }
    }
}
