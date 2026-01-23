import SwiftUI

struct CourseSearchView: View {
    @State private var searchText = ""
    @State private var courses = [
        GolfCourse(id: "1", name: "Pebble Beach", location: "California", holes: 18, difficulty: 7.5, facilities: CourseFacilities(drivingRange: true, puttingGreen: true), imageUrl: "", rating: 4.8),
        GolfCourse(id: "2", name: "Augusta National", location: "Georgia", holes: 18, difficulty: 9.0, facilities: CourseFacilities(drivingRange: true, puttingGreen: true), imageUrl: "", rating: 5.0),
        GolfCourse(id: "3", name: "St Andrews", location: "Scotland", holes: 18, difficulty: 8.0, facilities: CourseFacilities(drivingRange: true, puttingGreen: true), imageUrl: "", rating: 4.9)
    ]
    
    var filteredCourses: [GolfCourse] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredCourses) { course in
                VStack(alignment: .leading) {
                    Text(course.name).font(.headline)
                    Text(course.location).font(.subheadline).foregroundColor(.gray)
                    HStack {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text(String(format: "%.1f", course.rating))
                    }
                    .font(.caption)
                }
            }
            .searchable(text: $searchText, prompt: "Search by name, city...")
            .navigationTitle("Courses")
        }
    }
}
