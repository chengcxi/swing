import SwiftUI
import Combine

class GolfViewModel: ObservableObject {
    @Published var courses: [GolfCourse] = []
    
    init() {
        loadCourses()
    }
    
    func loadCourses() {
        self.courses = [
            GolfCourse(
                id: "1",
                name: "Pebble Beach",
                location: "California, USA",
                holes: 18,
                difficulty: 5.0,
                facilities: CourseFacilities(drivingRange: true, puttingGreen: true),
                imageUrl: "https://via.placeholder.com/400x300",
                rating: 4.8
            ),
            GolfCourse(
                id: "2",
                name: "St Andrews",
                location: "Scotland, UK",
                holes: 18,
                difficulty: 4.9,
                facilities: CourseFacilities(drivingRange: true, puttingGreen: true),
                imageUrl: "https://via.placeholder.com/400x300",
                rating: 5.0
            )
        ]
    }
}
