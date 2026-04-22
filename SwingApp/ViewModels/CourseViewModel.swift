import Foundation
import Combine

@MainActor
class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var searchText: String = ""
    @Published var filteredCourses: [Course] = []
    @Published var filteredUsers: [User] = []
    
    @Published var isLoading = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearch()
        Task {
            await fetchInitialCourses()
        }
    }
    
    func fetchInitialCourses() async {
        isLoading = true
        do {
            let fetchedCourses = try await GooglePlacesService.shared.searchGolfCourses(query: "")
            self.courses = fetchedCourses
            self.filteredCourses = fetchedCourses
        } catch {
            print("Failed to fetch initial courses: \(error)")
            // Fallback to mocks if network fails
            self.courses = Course.mocks
            self.filteredCourses = Course.mocks
        }
        isLoading = false
    }
    
    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self = self else { return }
                Task {
                    await self.performSearch(query: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) async {
        if query.isEmpty {
            self.filteredCourses = self.courses
            self.filteredUsers = []
            return
        }
        
        isLoading = true
        async let _fetchedCourses = GooglePlacesService.shared.searchGolfCourses(query: query)
        
        let limitQuery = "%\(query)%"
        async let _fetchedProfiles: [DBProfile] = (try? await supabase.from("profiles")
            .select()
            .or("username.ilike.\(limitQuery),full_name.ilike.\(limitQuery)")
            .limit(8)
            .execute()
            .value) ?? []

        do {
            let fetchedCourses = try await _fetchedCourses
            self.filteredCourses = fetchedCourses
        } catch {
            print("Failed to search courses: \(error)")
            self.filteredCourses = self.courses.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.location.localizedCaseInsensitiveContains(query) }
        }
        
        let fetchedProfiles = await _fetchedProfiles
        self.filteredUsers = fetchedProfiles.map { profile in
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
        
        isLoading = false
    }
}
