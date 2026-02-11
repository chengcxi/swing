import Foundation
import Supabase
import AuthenticationServices

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {
        Task {
            await checkSession()
            await setupAuthListener()
        }
    }
    
    // MARK: - Session Management
    
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
            await loadCurrentProfile()
        } catch {
            currentUser = nil
            currentProfile = nil
            isAuthenticated = false
        }
    }
    
    private func setupAuthListener() async {
        for await (event, session) in supabase.auth.authStateChanges {
            switch event {
            case .signedIn:
                currentUser = session?.user
                isAuthenticated = true
                await loadCurrentProfile()
            case .signedOut:
                currentUser = nil
                currentProfile = nil
                isAuthenticated = false
            case .userUpdated:
                currentUser = session?.user
            default:
                break
            }
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, username: String, fullName: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Validate username availability
        let existing: [Profile] = try await supabase
            .from("profiles")
            .select("id")
            .eq("username", value: username)
            .execute()
            .value
        
        guard existing.isEmpty else {
            throw AuthError.usernameExists
        }
        
        // Create auth user
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        
        guard let user = response.user else {
            throw AuthError.signUpFailed
        }
        
        // Create profile
        let profile = ProfileInsert(
            id: user.id,
            username: username,
            fullName: fullName
        )
        
        try await supabase
            .from("profiles")
            .insert(profile)
            .execute()
        
        currentUser = user
        isAuthenticated = true
        await loadCurrentProfile()
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        currentUser = session.user
        isAuthenticated = true
        await loadCurrentProfile()
    }
    
    // MARK: - Magic Link
    
    func signInWithMagicLink(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await supabase.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "swing://auth/callback")
        )
    }
    
    // MARK: - Sign In with Apple
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }
        
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )
        
        currentUser = session.user
        isAuthenticated = true
        
        // Check if profile exists, create if not
        await loadCurrentProfile()
        
        if currentProfile == nil {
            let username = credential.email?.components(separatedBy: "@").first
                ?? "user_\(UUID().uuidString.prefix(8))"
            
            let fullName: String? = {
                if let givenName = credential.fullName?.givenName,
                   let familyName = credential.fullName?.familyName {
                    return "\(givenName) \(familyName)"
                }
                return nil
            }()
            
            let profile = ProfileInsert(
                id: session.user.id,
                username: username,
                fullName: fullName
            )
            
            try await supabase
                .from("profiles")
                .insert(profile)
                .execute()
            
            await loadCurrentProfile()
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUser = nil
        currentProfile = nil
        isAuthenticated = false
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "swing://auth/reset-password")
        )
    }
    
    // MARK: - Profile Management
    
    func loadCurrentProfile() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            currentProfile = profile
        } catch {
            self.error = error
        }
    }
    
    func updateProfile(_ update: ProfileUpdate) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
        
        await loadCurrentProfile()
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case signUpFailed
    case notAuthenticated
    case profileNotFound
    case usernameExists
    case invalidCredential
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .profileNotFound:
            return "Profile not found."
        case .usernameExists:
            return "This username is already taken."
        case .invalidCredential:
            return "Invalid authentication credential."
        }
    }
}
