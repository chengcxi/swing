import SwiftUI

struct CourseListView: View {
    @StateObject private var viewModel = GolfViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.courses) { course in
                NavigationLink(destination: Text(course.name)) { // Placeholder destination
                    HStack {
                        AsyncImage(url: URL(string: course.imageUrl)) { image in
                             image.resizable()
                                 .aspectRatio(contentMode: .fill)
                         } placeholder: {
                             Rectangle().fill(Color.gray)
                         }
                         .frame(width: 80, height: 60)
                         .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            Text(course.name)
                                .font(.headline)
                            Text(course.location)
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text(String(format: "%.1f", course.rating))
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Courses")
        }
    }
}
