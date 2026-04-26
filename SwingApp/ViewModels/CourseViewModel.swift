import Foundation
import Combine
import CoreLocation

enum DiscoverFilter: String, CaseIterable {
    case all = "All"
    case nearby = "Nearby"
    case topRated = "Top Rated"
    case practiced = "Practiced"
}

@MainActor
class CourseViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var courses: [Course] = []
    @Published var searchText: String = ""
    @Published var filteredCourses: [Course] = []
    @Published var filteredUsers: [User] = []
    @Published var selectedFilter: DiscoverFilter = .all
    @Published var locationDenied = false
    @Published var isLoading = false

    private var allLoadedCourses: [Course] = []
    private var practicedCourses: [Course] = []
    private var userLocation: CLLocation?
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        locationManager.delegate = self
        setupSearch()
        Task { await fetchInitialCourses() }
    }

    // MARK: - Filters

    func setFilter(_ filter: DiscoverFilter) {
        selectedFilter = filter
        switch filter {
        case .all:
            filteredCourses = allLoadedCourses
        case .nearby:
            requestLocationIfNeeded()
            applyNearbyFilter()
        case .topRated:
            filteredCourses = allLoadedCourses.sorted { $0.difficulty > $1.difficulty }
        case .practiced:
            Task { await loadPracticedCourses() }
        }
    }

    private func applyNearbyFilter() {
        guard let me = userLocation else {
            // Wait for the location update; meanwhile show all
            filteredCourses = allLoadedCourses
            return
        }
        filteredCourses = allLoadedCourses
            .compactMap { course -> (Course, Double)? in
                guard let lat = course.latitude, let lng = course.longitude else { return nil }
                let courseLoc = CLLocation(latitude: lat, longitude: lng)
                return (course, me.distance(from: courseLoc))
            }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }

    private func loadPracticedCourses() async {
        isLoading = true
        defer { isLoading = false }
        guard let userId = try? await supabase.auth.session.user.id else {
            filteredCourses = []
            return
        }
        do {
            let rounds: [DBRound] = try await supabase.from("rounds")
                .select("*, course:golf_courses(*)")
                .eq("user_id", value: userId)
                .execute()
                .value

            // Group by course id, take one row per course
            var seen = Set<UUID>()
            var practiced: [Course] = []
            for round in rounds {
                guard let dbCourse = round.course, !seen.contains(dbCourse.id) else { continue }
                seen.insert(dbCourse.id)
                practiced.append(dbCourse.toCourse())
            }
            practicedCourses = practiced
            filteredCourses = practiced
        } catch {
            print("CourseViewModel.loadPracticedCourses failed: \(error)")
            filteredCourses = []
        }
    }

    // MARK: - Search

    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                Task { [weak self] in await self?.performSearch(query: text) }
            }
            .store(in: &cancellables)
    }

    func fetchInitialCourses() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await GooglePlacesService.shared.searchGolfCourses(query: "")
            if fetched.isEmpty {
                await loadFromSupabase(query: nil)
            } else {
                allLoadedCourses = fetched
                courses = fetched
                filteredCourses = fetched
            }
        } catch {
            print("CourseViewModel.fetchInitialCourses Places failed: \(error)")
            await loadFromSupabase(query: nil)
        }
    }

    /// Fallback: pull from our own golf_courses table when Google Places fails or returns empty.
    private func loadFromSupabase(query: String?) async {
        do {
            var supaQuery = supabase.from("golf_courses").select()
            if let query = query, !query.isEmpty {
                let pattern = "%\(query)%"
                supaQuery = supaQuery.or("name.ilike.\(pattern),city.ilike.\(pattern),state.ilike.\(pattern)")
            }
            let dbCourses: [DBGolfCourse] = try await supaQuery
                .order("name")
                .limit(40)
                .execute()
                .value
            let mapped = dbCourses.map { $0.toCourse() }
            allLoadedCourses = mapped
            courses = mapped
            filteredCourses = mapped
        } catch {
            print("CourseViewModel.loadFromSupabase failed: \(error)")
            allLoadedCourses = []
            filteredCourses = []
        }
    }

    private func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            filteredUsers = []
            setFilter(selectedFilter)
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Try Google Places, then fall back to Supabase
        var courseHits: [Course] = []
        do {
            courseHits = try await GooglePlacesService.shared.searchGolfCourses(query: trimmed)
        } catch {
            print("CourseViewModel.performSearch Places failed: \(error)")
        }
        if courseHits.isEmpty {
            await loadFromSupabase(query: trimmed)
            // loadFromSupabase already updated filteredCourses
        } else {
            allLoadedCourses = courseHits
            courses = courseHits
            // Re-apply current filter
            setFilter(selectedFilter)
        }

        // User search runs in parallel
        do {
            let pattern = "%\(trimmed)%"
            let profiles: [DBProfile] = try await supabase.from("profiles")
                .select()
                .or("username.ilike.\(pattern),full_name.ilike.\(pattern)")
                .limit(8)
                .execute()
                .value
            filteredUsers = profiles.map { $0.toUser() }
        } catch {
            print("CourseViewModel.performSearch users failed: \(error)")
            filteredUsers = []
        }
    }

    // MARK: - Location

    private func requestLocationIfNeeded() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationDenied = true
        @unknown default: break
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in
            self.userLocation = last
            if self.selectedFilter == .nearby {
                self.applyNearbyFilter()
            }
            manager.stopUpdatingLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationDenied = false
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.locationDenied = true
            default: break
            }
        }
    }
}

// MARK: - DB → local model helpers (file-private to avoid name conflicts)

fileprivate extension DBGolfCourse {
    func toCourse() -> Course {
        let loc = [city, state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        return Course(
            id: id,
            name: name,
            location: loc.isEmpty ? address : loc,
            holes: holes ?? 18,
            par: par ?? 72,
            difficulty: courseRating ?? 0,
            hasDrivingRange: false,
            hasPuttingGreen: false,
            latitude: latitude,
            longitude: longitude,
            googlePlaceId: googlePlaceId,
            city: city,
            state: state
        )
    }
}

fileprivate extension DBProfile {
    func toUser() -> User {
        User(
            id: id,
            username: username,
            fullName: fullName ?? username,
            isVerified: isUniversityVerified ?? false,
            profileImageName: avatarUrl ?? "",
            university: nil,
            handicap: handicap ?? 0.0,
            averageScore: 0.0,
            bestRound: 0,
            roundsPlayed: 0,
            badges: isUniversityVerified == true ? [.verified] : [],
            bio: bio,
            friendsCount: 0
        )
    }
}
