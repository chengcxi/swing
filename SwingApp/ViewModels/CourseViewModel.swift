import Foundation
import Combine
import GooglePlacesSwift
import CoreLocation

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

  private let locationManager = LocationManager()
  private let fallbackLocation = CLLocationCoordinate2D(latitude: 34.4140, longitude: -119.8489) // UCSB

  func fetchInitialCourses() async {
    isLoading = true
    defer { isLoading = false }

    let coordinate: CLLocationCoordinate2D
    do {
      coordinate = try await locationManager.requestLocation()
    } catch {
      print("Using fallback location: \(error)")
      coordinate = fallbackLocation
    }

    let region = CircularCoordinateRegion(center: coordinate, radius: 50_000)
    let request = SearchByTextRequest(
      textQuery: "golf course",
      placeProperties: [.placeID, .displayName, .formattedAddress, .coordinate],
      locationBias: region,
      maxResultCount: 20
    )

    switch await PlacesClient.shared.searchByText(with: request) {
    case .success(let places):
      let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      let sortedPlaces = sortByDistance(places, from: userLocation)
      let fetched = sortedPlaces.map { Course(from: $0) }
      self.courses = fetched
      self.filteredCourses = fetched

    case .failure(let error):
      print("Failed to fetch initial courses: \(error)")
      self.courses = []
      self.filteredCourses = []
    }
  }

  private func sortByDistance(_ places: [Place], from userLocation: CLLocation) -> [Place] {
    places.sorted { (lhs: Place, rhs: Place) -> Bool in
      let lhsDist = distance(from: userLocation, to: lhs.location)
      let rhsDist = distance(from: userLocation, to: rhs.location)
      return lhsDist < rhsDist
    }
  }

  private func distance(from userLocation: CLLocation, to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
    let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    return userLocation.distance(from: target)
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
    defer { isLoading = false }

    async let fetchedCoursesTask = searchCourses(query: query)
    async let fetchedProfilesTask = searchProfiles(query: query)

    let (fetchedCourses, fetchedProfiles) = await (fetchedCoursesTask, fetchedProfilesTask)

    self.filteredCourses = fetchedCourses
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
  }

  private func searchCourses(query: String) async -> [Course] {
    let coordinate: CLLocationCoordinate2D
    do {
      coordinate = try await locationManager.requestLocation()
    } catch {
      coordinate = fallbackLocation
    }

    let region = CircularCoordinateRegion(center: coordinate, radius: 200_000)
    let request = SearchByTextRequest(
      textQuery: "\(query) golf course",
      placeProperties: [.placeID, .displayName, .formattedAddress, .coordinate],
      locationBias: region,
      maxResultCount: 20
    )

    switch await PlacesClient.shared.searchByText(with: request) {
    case .success(let places):
      let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      let sorted = sortByDistance(places, from: userLocation)
      return sorted.map { Course(from: $0) }

    case .failure(let error):
      print("Failed to search courses: \(error)")
      return self.courses.filter {
        $0.name.localizedCaseInsensitiveContains(query)
        || $0.location.localizedCaseInsensitiveContains(query)
      }
    }
  }

  private func searchProfiles(query: String) async -> [DBProfile] {
    let likeQuery = "%\(query)%"
    do {
      return try await supabase.from("profiles")
        .select()
        .or("username.ilike.\(likeQuery),full_name.ilike.\(likeQuery)")
        .limit(8)
        .execute()
        .value
    } catch {
      print("Failed to search profiles: \(error)")
      return []
    }
  }
}

extension Course {
  init(from place: Place) {
    self.id = UUID()
    self.name = place.displayName ?? place.formattedAddress ?? "Unknown Course"
    self.location = place.formattedAddress ?? "Unknown Location"
    self.latitude = place.location.latitude
    self.longitude = place.location.longitude
    self.googlePlaceId = place.placeID
  }
}
