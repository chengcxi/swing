import SwiftUI

struct CourseRow: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(course.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.gray)
                Text(course.location)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 12) {
                Label("\(course.holes) Holes", systemImage: "flag")
                    .font(.caption)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                
                Label("Difficulty: \(String(format: "%.1f", course.difficulty))", systemImage: "gauge")
                    .font(.caption)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
            
            HStack(spacing: 12) {
                if course.hasDrivingRange {
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max")
                        Text("driving range")
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "0A4A35"))
                    .padding(6)
                    .background(Color(hex: "0A4A35").opacity(0.1))
                    .cornerRadius(6)
                }
                
                if course.hasPuttingGreen {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf")
                        Text("putting green")
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "0A4A35"))
                    .padding(6)
                    .background(Color(hex: "0A4A35").opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
