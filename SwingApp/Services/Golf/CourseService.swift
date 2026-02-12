import Foundation
import CoreLocation

@MainActor
class CourseService: ObservableObject {
    static let shared = CourseService()
    
    @Published var courses: [GolfCourse] = []
    @Published var nearbyCourses: [GolfCourse] = []
    @Published var searchResults: [GolfCourse] = []
    @Published var favoriteCourses: [FavoriteCourse] = []
    @Published var isLoading = false
    
    // MARK: - Search Courses
    
    func searchCourses(query: String) async throws -> [GolfCourse] {
        guard !query.isEmpty else {
            searchResults = []
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let results: [GolfCourse] = try await supabase
            .from("golf_courses")
            .select()
            .or("name.ilike.%\(query)%,city.ilike.%\(query)%,state.ilike.%\(query)%")
            .order("name")
            .limit(20)
            .execute()
            .value
        
        searchResults = results
        return results
    }
    
    // MARK: - Nearby Courses
    
    func fetchNearbyCourses(location: CLLocationCoordinate2D, radiusKm: Double = 50) async throws -> [GolfCourse] {
        isLoading = true
        defer { isLoading = false }
        
        let latDelta = radiusKm / 111.0
        let lonDelta = radiusKm / (111.0 * cos(location.latitude * .pi / 180))
        
        let courses: [GolfCourse] = try await supabase
            .from("golf_courses")
            .select()
            .gte("latitude", value: location.latitude - latDelta)
            .lte("latitude", value: location.latitude + latDelta)
            .gte("longitude", value: location.longitude - lonDelta)
            .lte("longitude", value: location.longitude + lonDelta)
            .execute()
            .value
        
        let filtered = courses
            .map { course -> (course: GolfCourse, distance: Double) in
                let dist = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    .distance(from: CLLocation(latitude: course.latitude, longitude: course.longitude)) / 1000
                return (course, dist)
            }
            .filter { $0.distance <= radiusKm }
            .sorted { $0.distance < $1.distance }
            .map { $0.course }
        
        nearbyCourses = filtered
        return filtered
    }
    
    // MARK: - Get or Create Course
    
    func getOrCreateCourse(_ insert: GolfCourseInsert) async throws -> GolfCourse {
        // Check if exists by Google Place ID
        if let placeId = insert.googlePlaceId {
            let existing: [GolfCourse] = try await supabase
                .from("golf_courses")
                .select()
                .eq("google_place_id", value: placeId)
                .limit(1)
                .execute()
                .value
            
            if let course = existing.first {
                return course
            }
        }
        
        // Create new
        let newCourse: GolfCourse = try await supabase
            .from("golf_courses")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        
        return newCourse
    }
    
    // MARK: - Favorite Courses
    
    func fetchFavoriteCourses(userId: UUID) async throws -> [FavoriteCourse] {
        let favorites: [FavoriteCourse] = try await supabase
            .from("favorite_courses")
            .select("*, course:golf_courses(*)")
            .eq("user_id", value: userId.uuidString)
            .order("rank")
            .execute()
            .value
        
        favoriteCourses = favorites
        return favorites
    }
    
    func addFavoriteCourse(courseId: UUID) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        let nextRank = favoriteCourses.count + 1
        
        try await supabase
            .from("favorite_courses")
            .insert([
                "user_id": userId.uuidString,
                "course_id": courseId.uuidString,
                "rank": nextRank
            ])
            .execute()
        
        _ = try await fetchFavoriteCourses(userId: userId)
    }
    
    func updateFavoriteCourseRanks(_ favorites: [FavoriteCourse]) async throws {
        for (index, favorite) in favorites.enumerated() {
            try await supabase
                .from("favorite_courses")
                .update(["rank": index + 1])
                .eq("id", value: favorite.id.uuidString)
                .execute()
        }
        
        if let userId = AuthService.shared.currentUser?.id {
            _ = try await fetchFavoriteCourses(userId: userId)
        }
    }
    
    func removeFavoriteCourse(id: UUID) async throws {
        try await supabase
            .from("favorite_courses")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        favoriteCourses.removeAll { $0.id == id }
    }
}