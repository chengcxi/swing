import SwiftUI

struct CourseSearchView: View {
    @StateObject private var viewModel = CourseViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search courses or cities...", text: $viewModel.searchText)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top)
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterButton(title: "All Holes", isSelected: true)
                        FilterButton(title: "Practice Facility", isSelected: false)
                        FilterButton(title: "Public", isSelected: false)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)
                
                // Course List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.filteredCourses) { course in
                            CourseRow(course: course)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Courses")
            .background(Color(white: 0.95))
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color(hex: "0A4A35") : Color.white)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
    }
}
