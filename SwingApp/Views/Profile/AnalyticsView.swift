
import SwiftUI
import Charts

struct AnalyticsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Trends")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(Round.mocks) { round in
                    LineMark(
                        x: .value("Date", round.date),
                        y: .value("Score", round.score)
                    )
                    .foregroundStyle(Color(hex: "0A4A35"))
                    
                    PointMark(
                        x: .value("Date", round.date),
                        y: .value("Score", round.score)
                    )
                    .foregroundStyle(Color(hex: "0A4A35"))
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
