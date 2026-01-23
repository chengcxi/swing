import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject var viewModel = AnalyticsViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Text("Filter by Course:")
                Picker("Course", selection: $viewModel.selectedCourseFilter) {
                    ForEach(viewModel.availableCourses, id: \.self) { course in
                        Text(course).tag(course)
                    }
                }
                .onChange(of: viewModel.selectedCourseFilter) { _ in
                    viewModel.filterScores()
                }
            }
            .padding()
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(viewModel.scores.enumerated()), id: \.offset) { index, item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Score", item.score)
                        )
                        .symbol(.circle)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 300)
                .padding()
            } else {
                Text("Charts require iOS 16+")
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .navigationTitle("Analytics")
    }
}
