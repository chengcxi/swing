import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showVerificationAlert = false
    @State private var emailInput = ""
    
    var user: User? { appViewModel.currentUser }
    // Mock stats calculation from user
    var stats: UserStats? { 
        // In real app, stats would be in User or separate specific model
        return UserStats(bestRound: 72, averageScore: 78.5, roundsPlayed: 45, handicap: user?.handicap ?? 0.0)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack {
                    AsyncImage(url: URL(string: user?.avatar ?? "")) { image in
                         image.resizable()
                             .aspectRatio(contentMode: .fill)
                     } placeholder: {
                         Circle().fill(Color.gray)
                     }
                     .frame(width: 100, height: 100)
                     .clipShape(Circle())
                     .padding(.top)
                    
                    Text(user?.name ?? "User")
                        .font(.title2)
                        .bold()
                    
                    Text(user?.username ?? "@username")
                        .foregroundColor(.gray)
                    
                    if let description = user?.description {
                        Text(description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if let university = user?.university {
                         Text(university)
                             .font(.headline)
                             .foregroundColor(.purple)
                    }
                    
                    HStack {
                        if (user?.isVerified ?? false) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Verified Student")
                            }
                            .font(.caption)
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        } else {
                            Button("Verify University") {
                                showVerificationAlert = true
                            }
                            .font(.caption)
                            .padding(6)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                        
                        if (user?.isPro ?? false) {
                            Text("Pro")
                                .font(.caption)
                                .padding(6)
                                .background(Color.yellow.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                        }
                    }
                    
                    if let rank = user?.universityRank {
                         Text("University Rank: #\(rank)")
                             .font(.subheadline)
                             .bold()
                             .foregroundColor(.purple)
                             .padding(.top, 4)
                    }
                }
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    StatCard(title: "Handicap", value: String(format: "%.1f", stats?.handicap ?? 0.0))
                    StatCard(title: "Rounds", value: "\(stats?.roundsPlayed ?? 0)")
                    StatCard(title: "Avg Score", value: String(format: "%.1f", stats?.averageScore ?? 0.0))
                    StatCard(title: "Best Round", value: "\(stats?.bestRound ?? 0)")
                }
                .padding()
                
                // Badges
                if let badges = user?.badges, !badges.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Badges")
                            .font(.headline)
                            .padding(.leading)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(badges) { badge in
                                    VStack {
                                        Image(systemName: badge.icon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.yellow)
                                        Text(badge.name)
                                            .font(.caption2)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Analytics
                NavigationLink(destination: AnalyticsView()) {
                    Text("View Detailed Analytics")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding()
                }
                
                Spacer()
            }
        }
        .navigationTitle("Profile")
        .alert("Verify Email", isPresented: $showVerificationAlert) {
            TextField("Email", text: $emailInput)
            Button("Verify") {
                appViewModel.verifyEmail(emailInput)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your .edu email to verify.")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
