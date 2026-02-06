import Foundation

class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var searchText: String = "" {
        didSet {
            // Debounce or just trigger
            Task {
                await loadCourses()
            }
        }
    }
    
    init() {
        Task {
            await loadCourses()
        }
    }
    
    @MainActor
    func loadCourses() async {
        do {
            self.courses = try await DataService.shared.fetchCourses(search: searchText)
        } catch {
            print("Error fetching courses: \(error)")
        }
    }
    
    // filteredCourses property is no longer needed if we update `courses` directly based on search
    // But if the view uses it, we should check. 
    // The previous implementation exposed `filteredCourses`. 
    // I will expose `courses` as the source of truth now, but I must make sure the View uses `courses`.
    // Or I can keep a computed property that just returns `courses` to avoid breaking changes if possible.
    var filteredCourses: [Course] {
        return courses
    }
}
