import SwiftUI

struct RankingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(appViewModel.currentUser?.username ?? "User")'s Course Rankings")
                .font(.headline)
                .padding(.horizontal)
            
            // Mock Rankings
            VStack(spacing: 12) {
                RankingRow(rank: 1, courseName: "Sandpiper Golf Club", location: "Goleta, CA")
                RankingRow(rank: 2, courseName: "Riviera Country Club", location: "Pacific Palisades, CA")
                RankingRow(rank: 3, courseName: "Alisal River Course", location: "Solvang, CA")
                RankingRow(rank: 4, courseName: "Rustic Canyon Golf Course", location: "Moorpark, CA")
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct RankingRow: View {
    let rank: Int
    let courseName: String
    let location: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(rank == 1 ? Color(hex: "DAA520") : (rank == 2 ? Color.gray : (rank == 3 ? Color(hex: "CD7F32") : Color.white)))
                    .frame(width: 30, height: 30)
                
                if rank > 3 {
                    Text("\(rank).")
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    Text("\(rank)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            Image(systemName: "mappin.and.ellipse")
                .foregroundColor(Color(hex: "0A4A35"))
            
            VStack(alignment: .leading) {
                Text(courseName)
                    .font(.headline)
                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
