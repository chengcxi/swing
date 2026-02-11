import Foundation
import CoreLocation

@MainActor
class CourseService: ObservableObject {
    static let shared = CourseService()
    
    @Published var courses: [GolfCourse] = []
    @Published var nearbyCourses: [GolfCourse] = []
    @Published var searchResults: [GolfCourse] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Fetch All Courses
    
    func fetchAllCourses(limit: Int = 100) async throws -> [GolfCourse] {
        isLoading = true
        defer { isLoading = false }
        
        let courses: [GolfCourse] = try await supabase
            .from("golf_courses")
            .select()
            .order("name")
            .limit(limit)
            .execute()
            .value
        
        self.courses = courses
        return courses
    }
    
    // MARK: - Get Single Course
    
    func fetchCourse(id: UUID) async throws -> GolfCourse {
        let course: GolfCourse = try await supabase
            .from("golf_courses")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return course
    }
    
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
    
    func fetchNearbyCourses(
        location: CLLocationCoordinate2D,
        radiusKm: Double = Config.defaultSearchRadiusKm
    ) async throws -> [GolfCourse] {
        isLoading = true
        defer { isLoading = false }
        
        // Bounding box for initial filter
        let latDelta = radiusKm / 111.0
        let lonDelta = radiusKm / (111.0 * cos(location.latitude * .pi / 180))
        
        let minLat = location.latitude - latDelta
        let maxLat = location.latitude + latDelta
        let minLon = location.longitude - lonDelta
        let maxLon = location.longitude + lonDelta
        
        let courses: [GolfCourse] = try await supabase
            .from("golf_courses")
            .select()
            .gte("latitude", value: minLat)
            .lte("latitude", value: maxLat)
            .gte("longitude", value: minLon)
            .lte("longitude", value: maxLon)
            .execute()
            .value
        
        // Sort by actual distance
        let filtered = courses
            .map { course -> (course: GolfCourse, distance: Double) in
                let distance = self.calculateDistance(from: location, to: course.coordinate)
                return (course, distance)
            }
            .filter { $0.distance <= radiusKm }
            .sorted { $0.distance < $1.distance }
            .map { $0.course }
        
        nearbyCourses = filtered
        return filtered
    }
    
    // MARK: - Create Course
    
    func createCourse(_ course: GolfCourseInsert) async throws -> GolfCourse {
        let newCourse: GolfCourse = try await supabase
            .from("golf_courses")
            .insert(course)
            .select()
            .single()
            .execute()
            .value
        
        courses.append(newCourse)
        return newCourse
    }
    
    // MARK: - Find by Google Place ID
    
    func findByGooglePlaceId(_ placeId: String) async throws -> GolfCourse? {
        let courses: [GolfCourse] = try await supabase
            .from("golf_courses")
            .select()
            .eq("google_place_id", value: placeId)
            .limit(1)
            .execute()
            .value
        
        return courses.first
    }
    
    // MARK: - Helpers
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000 // km
    }
}
