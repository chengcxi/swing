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
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if let user = appViewModel.currentUser {
                        // Hero header (Phantom-wallet style)
                        ProfileHeroCard(user: user)
                            .padding(.horizontal)
                            .padding(.top, 4)

                        // Quick stats row (Duolingo-style)
                        QuickStatsRow(user: user)
                            .padding(.top, 20)

                        // Badges row
                        BadgesRow(badges: user.badges)
                            .padding(.top, 16)
                    }

                    // Tab Picker
                    ProfileTabPicker(selectedTab: $selectedTab)
                        .padding(.top, 20)

                    // Content
                    Group {
                        switch selectedTab {
                        case .rounds:
                            RoundsListView()
                        case .rankings:
                            RankingsView()
                        case .analytics:
                            AnalyticsView()
                        }
                    }
                    .padding(.top, 16)

                    Spacer().frame(height: 100)
                }
            }
            .background(GolfrColors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(appViewModel.currentUser.map { "@\($0.username)" } ?? "Profile")
                        .font(GolfrFonts.title())
                        .foregroundColor(GolfrColors.textPrimary)
                        .fixedSize()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        GolfrNavButton(icon: "square.and.arrow.up") {}
                        GolfrNavButton(icon: "gearshape") {}
                    }
                }
            }
        }
    }
}

// MARK: - Profile Hero Card (Phantom-wallet-style)

struct ProfileHeroCard: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            // Avatar + Name
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(GolfrColors.cream.opacity(0.2))
                        .frame(width: 68, height: 68)

                    Circle()
                        .stroke(GolfrColors.cream.opacity(0.4), lineWidth: 2)
                        .frame(width: 68, height: 68)

                    Text(user.fullName.prefix(1).uppercased())
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(GolfrColors.cream)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(user.fullName)
                            .font(GolfrFonts.title())
                            .foregroundColor(.white)

                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(GolfrColors.gold)
                        }
                    }

                    Text("@\(user.username)")
                        .font(GolfrFonts.callout())
                        .foregroundColor(GolfrColors.textOnDarkMuted)

                    if let uni = user.university {
                        HStack(spacing: 4) {
                            Image(systemName: "building.columns")
                                .font(.system(size: 10))
                            Text(uni)
                                .font(GolfrFonts.caption())
                        }
                        .foregroundColor(GolfrColors.textOnDarkMuted)
                    }
                }

                Spacer()
            }

            // Handicap display (like a wallet balance)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Handicap Index")
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textOnDarkMuted)
                    Text(String(format: "%.1f", user.handicap))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(GolfrColors.cream)
                }

                Spacer()

                // Trend indicator
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("-0.3")
                        .font(GolfrFonts.callout())
                }
                .foregroundColor(GolfrColors.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(GolfrColors.success.opacity(0.15))
                )
            }

            // Edit profile button
            Button(action: {}) {
                Text("Edit Profile")
                    .font(GolfrFonts.callout())
                    .foregroundColor(GolfrColors.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(20)
        .golfrDarkCard()
    }
}

// MARK: - Quick Stats Row

struct QuickStatsRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 10) {
            QuickStatItem(
                icon: "trophy.fill",
                iconColor: GolfrColors.gold,
                value: "\(user.bestRound)",
                label: "Best"
            )

            QuickStatItem(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: GolfrColors.primaryLight,
                value: String(format: "%.0f", user.averageScore),
                label: "Average"
            )

            QuickStatItem(
                icon: "calendar",
                iconColor: GolfrColors.info,
                value: "\(user.roundsPlayed)",
                label: "Rounds"
            )

            QuickStatItem(
                icon: "flame.fill",
                iconColor: GolfrColors.warning,
                value: "3",
                label: "Streak"
            )
        }
        .padding(.horizontal)
    }
}

struct QuickStatItem: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            Text(value)
                .font(GolfrFonts.title3())
                .foregroundColor(GolfrColors.textPrimary)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(GolfrColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .golfrCard(cornerRadius: 14)
    }
}

// MARK: - Badges Row (Duolingo-style)

struct BadgesRow: View {
    let badges: [Badge]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Badge.allCases, id: \.self) { badge in
                    BadgeItem(badge: badge, isEarned: badges.contains(badge))
                }
            }
            .padding(.horizontal)
        }
    }
}

extension Badge: CaseIterable {
    static var allCases: [Badge] = [.verified, .top10, .star, .streak]

    var displayName: String {
        switch self {
        case .verified: return "Verified"
        case .top10: return "Top 10"
        case .star: return "All-Star"
        case .streak: return "On Fire"
        }
    }

    var icon: String {
        switch self {
        case .verified: return "checkmark.seal.fill"
        case .top10: return "medal.fill"
        case .star: return "star.fill"
        case .streak: return "flame.fill"
        }
    }

    var badgeColor: Color {
        switch self {
        case .verified: return GolfrColors.info
        case .top10: return GolfrColors.gold
        case .star: return GolfrColors.warning
        case .streak: return GolfrColors.error
        }
    }
}

struct BadgeItem: View {
    let badge: Badge
    let isEarned: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isEarned ? badge.badgeColor.opacity(0.15) : Color.gray.opacity(0.08))
                    .frame(width: 48, height: 48)

                Image(systemName: badge.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isEarned ? badge.badgeColor : Color.gray.opacity(0.3))
            }

            Text(badge.displayName)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(isEarned ? GolfrColors.textPrimary : GolfrColors.textSecondary)
        }
    }
}

// MARK: - Profile Tab Picker

struct ProfileTabPicker: View {
    @Binding var selectedTab: ProfileView.ProfileTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ProfileView.ProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(GolfrFonts.callout())
                        .foregroundColor(selectedTab == tab ? .white : GolfrColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? GolfrColors.primary : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(GolfrColors.backgroundElevated)
        )
        .padding(.horizontal)
    }
}

// MARK: - Rounds List View (redesigned)

struct RoundsListView: View {
    let rounds = Round.mocks

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Rounds")
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)
                Spacer()
                Button(action: {}) {
                    Text("See All")
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.primaryLight)
                }
            }
            .padding(.horizontal)

            ForEach(rounds) { round in
                RoundListItem(round: round)
                    .padding(.horizontal)
            }
        }
    }
}

struct RoundListItem: View {
    let round: Round

    var body: some View {
        HStack(spacing: 14) {
            // Score badge
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(GolfrColors.primary.opacity(0.1))
                    .frame(width: 56, height: 56)

                Text("\(round.score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(GolfrColors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(round.courseName)
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin")
                            .font(.system(size: 9))
                        Text(round.location)
                            .font(GolfrFonts.caption())
                    }
                    .foregroundColor(GolfrColors.textSecondary)

                    Text("\(round.holes) holes")
                        .golfrChip(color: GolfrColors.primary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(dateString(from: round.date))
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(GolfrColors.textSecondary.opacity(0.5))
            }
        }
        .padding(12)
        .golfrCard(cornerRadius: 14)
    }

    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
