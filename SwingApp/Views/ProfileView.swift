import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedTab: ProfileTab = .rounds
    
    enum ProfileTab: String, CaseIterable {
        case rounds = "Rounds"
        case rankings = "Rankings"
        case analytics = "Analytics"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    if let user = appViewModel.currentUser {
                        VStack(spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(user.profileImageName)
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(Circle())
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(user.fullName)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        
                                        if user.isVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.blue)
                                        }
                                        
                                        if user.badges.contains(.star) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    
                                    Text(user.username)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            
                            // Stats Cards
                            HStack(spacing: 8) {
                                StatsCard(title: "Best Round", value: "\(user.bestRound)", icon: "trophy")
                                StatsCard(title: "Average Score", value: String(format: "%.1f", user.averageScore), icon: "chart.xyaxis.line")
                                StatsCard(title: "Rounds Played", value: "\(user.roundsPlayed)", icon: "calendar")
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
                    }
                    
                    // Tab Picker
                    HStack {
                        ForEach(ProfileTab.allCases, id: \.self) { tab in
                            Button(action: {
                                selectedTab = tab
                            }) {
                                Text(tab.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == tab ? .bold : .regular)
                                    .foregroundColor(selectedTab == tab ? .primary : .gray)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        VStack {
                                            Spacer()
                                            if selectedTab == tab {
                                                Rectangle()
                                                    .fill(Color.primary)
                                                    .frame(height: 2)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .frame(height: 1)
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .background(Color.white)
                    
                    // Content
                    VStack {
                        switch selectedTab {
                        case .rounds:
                            RoundsListView()
                        case .rankings:
                            RankingsView()
                        case .analytics:
                            AnalyticsView()
                        }
                    }
                    .background(Color(white: 0.95))
                    .frame(minHeight: 400) // Ensure some height
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct RoundsListView: View {
    // Determine this from a ViewModel in real app
    let rounds = Round.mocks
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Rounds")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ForEach(rounds) { round in
                HStack {
                    VStack(alignment: .leading) {
                        Text(round.courseName)
                            .font(.headline)
                        Text("\(round.location) • \(round.holes) 🏳️")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Played on \(timeString(from: round.date))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "0A4A35"), lineWidth: 2)
                            .frame(width: 50, height: 50)
                        Text("\(round.score)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0A4A35"))
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
    
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
