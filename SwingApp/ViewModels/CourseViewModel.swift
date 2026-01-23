import Foundation

class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var searchText: String = ""
    
    init() {
        self.courses = Course.mocks
    }
    
    var filteredCourses: [Course] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.location.localizedCaseInsensitiveContains(searchText) }
        }
    }
}
