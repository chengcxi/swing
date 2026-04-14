import Foundation
import Combine

@MainActor
class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var searchText: String = ""
    @Published var filteredCourses: [Course] = []
    
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
            return
        }
        
        isLoading = true
        do {
            let fetchedCourses = try await GooglePlacesService.shared.searchGolfCourses(query: query)
            self.filteredCourses = fetchedCourses
        } catch {
            print("Failed to search courses: \(error)")
            self.filteredCourses = self.courses.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.location.localizedCaseInsensitiveContains(query) }
        }
        isLoading = false
    }
}
