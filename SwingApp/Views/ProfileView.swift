import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedTab: ProfileTab = .rounds
    @State private var showMenu = false
    @State private var showEditProfile = false
    @State private var showAllRounds = false

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
                        // Hero header (white with green accent)
                        ProfileHeroCard(user: user, onEditTapped: {
                            showEditProfile = true
                        })
                            .padding(.horizontal)
                            .padding(.top, 2)

                        // Quick stats banner
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
                            RoundsListView(onSeeAllTapped: {
                                showAllRounds = true
                            })
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
                        .font(GolfrFonts.pageTitle())
                        .foregroundColor(GolfrColors.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(GolfrColors.backgroundCard))
                        .fixedSize()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    GolfrNavButton(icon: "line.3.horizontal") {
                        showMenu = true
                    }
                }
            }
            .sheet(isPresented: $showMenu) {
                BurgerMenuSheet()
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = appViewModel.currentUser {
                    EditProfileSheet(user: user)
                        .environmentObject(appViewModel)
                }
            }
            .sheet(isPresented: $showAllRounds) {
                AllRoundsSheet()
            }
        }
    }
}

// MARK: - Burger Menu Sheet

struct BurgerMenuSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                BurgerMenuItem(icon: "bookmark", title: "Saved Posts")
                BurgerMenuItem(icon: "heart", title: "Liked Posts")
                BurgerMenuItem(icon: "bell", title: "Notifications")
                BurgerMenuItem(icon: "link", title: "Invite Friends")
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GolfrColors.primaryLight)
                }
            }
        }
    }
}

struct BurgerMenuItem: View {
    let icon: String
    let title: String

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(GolfrColors.primaryLight)
                    .frame(width: 28)
                Text(title)
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(GolfrColors.textSecondary)
            }
        }
    }
}

// MARK: - Profile Hero Card (White with green accent)

struct ProfileHeroCard: View {
    let user: User
    var onEditTapped: () -> Void = {}

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                // Avatar + Name
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(GolfrColors.primaryLight.opacity(0.1))
                            .frame(width: 68, height: 68)

                        Circle()
                            .stroke(GolfrColors.primaryLight, lineWidth: 2)
                            .frame(width: 68, height: 68)

                        Text(user.fullName.prefix(1).uppercased())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(GolfrColors.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(user.fullName)
                                .font(GolfrFonts.title())
                                .foregroundColor(GolfrColors.textPrimary)

                            if user.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(GolfrColors.primaryLight)
                            }
                        }

                        Text("@\(user.username)")
                            .font(GolfrFonts.callout())
                            .foregroundColor(GolfrColors.textSecondary)

                        if let uni = user.university {
                            HStack(spacing: 4) {
                                Image(systemName: "building.columns")
                                    .font(.system(size: 10))
                                Text(uni)
                                    .font(GolfrFonts.caption())
                            }
                            .foregroundColor(GolfrColors.textSecondary)
                        }
                    }

                    Spacer()
                }

                // Bio
                if let bio = user.bio {
                    Text(bio)
                        .font(GolfrFonts.body())
                        .foregroundColor(GolfrColors.textPrimary.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Friends & Rounds counts
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Text("\(user.friendsCount)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(GolfrColors.textPrimary)
                        Text("friends")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(GolfrColors.textSecondary)
                    }

                    HStack(spacing: 4) {
                        Text("\(user.roundsPlayed)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(GolfrColors.textPrimary)
                        Text("rounds")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(GolfrColors.textSecondary)
                    }
                }

                // Handicap display
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Handicap Index")
                            .font(GolfrFonts.caption())
                            .foregroundColor(GolfrColors.textSecondary)
                        Text(String(format: "%.1f", user.handicap))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(GolfrColors.primary)
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
            }
            .padding(20)

            // Edit button — top right of card
            Button(action: onEditTapped) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GolfrColors.textSecondary)
                    .padding(8)
                    .background(Circle().fill(GolfrColors.backgroundElevated))
            }
            .padding(14)
        }
        .golfrCard(cornerRadius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(GolfrColors.primaryLight.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Quick Stats Row (Banner style)

struct QuickStatsRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            StatBanner(
                icon: "trophy.fill",
                value: "\(user.bestRound)",
                label: "Best"
            )

            StatBanner(
                icon: "chart.line.uptrend.xyaxis",
                value: String(format: "%.0f", user.averageScore),
                label: "Average"
            )

            StatBanner(
                icon: "calendar",
                value: "\(user.roundsPlayed)",
                label: "Rounds"
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Banner Shape

struct BannerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cr: CGFloat = 14
        let notch: CGFloat = 18

        path.move(to: CGPoint(x: rect.minX + cr, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - cr, y: rect.minY + cr),
                     radius: cr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cr))
        path.addArc(center: CGPoint(x: rect.minX + cr, y: rect.minY + cr),
                     radius: cr, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        return path
    }
}

struct StatBanner: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(GolfrColors.textOnDarkMuted)

            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 22)
        .background(
            BannerShape()
                .fill(GolfrColors.cardGradient)
        )
        .shadow(color: GolfrColors.primary.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Badges Row

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
    static var allCases: [Badge] = [.verified, .top10, .star]

    var displayName: String {
        switch self {
        case .verified: return "Verified"
        case .top10: return "Top 10"
        case .star: return "All-Star"
        }
    }

    var icon: String {
        switch self {
        case .verified: return "checkmark.seal.fill"
        case .top10: return "medal.fill"
        case .star: return "star.fill"
        }
    }

    var badgeColor: Color {
        switch self {
        case .verified: return GolfrColors.primaryLight
        case .top10: return GolfrColors.primaryMedium
        case .star: return GolfrColors.primary
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

// MARK: - Rounds List View

struct RoundsListView: View {
    let rounds = Round.mocks
    var onSeeAllTapped: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Rounds")
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)
                Spacer()
                Button(action: onSeeAllTapped) {
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
    @State private var showPostConfirmation = false
    @State private var posted = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                // Score badge — fixed size, pinned to top
                Text("\(round.score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(GolfrColors.primary)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GolfrColors.primary.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(round.courseName)
                        .font(GolfrFonts.headline())
                        .foregroundColor(GolfrColors.textPrimary)

                    Text("\(round.holes) holes")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(GolfrColors.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(GolfrColors.primary.opacity(0.12)))
                        .fixedSize()

                    HStack(spacing: 5) {
                        Image(systemName: "mappin")
                            .font(.system(size: 9))
                        Text(round.location)
                            .font(GolfrFonts.caption())
                            .lineLimit(1)
                    }
                    .foregroundColor(GolfrColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(dateString(from: round.date))
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textSecondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(GolfrColors.textSecondary.opacity(0.5))
                }
            }

            // Post link — aligned with chevron above
            Button(action: {
                if posted {
                    // Already posted
                } else {
                    showPostConfirmation = true
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: posted ? "checkmark.circle.fill" : "square.and.arrow.up")
                        .font(.system(size: 11))
                    Text(posted ? "Posted" : "Post")
                        .font(GolfrFonts.caption())
                }
                .foregroundColor(posted ? GolfrColors.primary : GolfrColors.primaryLight)
            }
            .padding(.top, -16)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .golfrCard(cornerRadius: 14)
        .alert("Share to Feed", isPresented: $showPostConfirmation) {
            Button("Post", role: nil) {
                withAnimation { posted = true }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Share your \(round.score) at \(round.courseName) to your feed?")
        }
    }

    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Edit Profile Sheet (Instagram-style)

struct EditProfileSheet: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    let user: User

    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var university: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GolfrColors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(GolfrColors.primaryLight.opacity(0.1))
                                .frame(width: 86, height: 86)

                            Circle()
                                .stroke(GolfrColors.primaryLight, lineWidth: 2)
                                .frame(width: 86, height: 86)

                            Text(fullName.prefix(1).uppercased())
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(GolfrColors.primary)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(GolfrColors.primary)
                                .background(Circle().fill(GolfrColors.backgroundPrimary).frame(width: 24, height: 24))
                        }
                        .padding(.top, 12)

                        // Fields
                        VStack(spacing: 16) {
                            EditProfileField(label: "Name", text: $fullName)
                            EditProfileField(label: "Username", text: $username)
                            EditProfileField(label: "Bio", text: $bio, isMultiline: true)
                            EditProfileField(label: "University", text: $university)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(GolfrColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        appViewModel.updateProfile(
                            fullName: fullName,
                            username: username,
                            bio: bio,
                            university: university.isEmpty ? nil : university
                        )
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GolfrColors.primary)
                }
            }
        }
        .onAppear {
            fullName = user.fullName
            username = user.username
            bio = user.bio ?? ""
            university = user.university ?? ""
        }
    }
}

struct EditProfileField: View {
    let label: String
    @Binding var text: String
    var isMultiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(GolfrFonts.caption())
                .foregroundColor(GolfrColors.textSecondary)

            if isMultiline {
                TextEditor(text: $text)
                    .font(GolfrFonts.body())
                    .frame(height: 80)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GolfrColors.backgroundCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(GolfrColors.textSecondary.opacity(0.15), lineWidth: 1)
                    )
            } else {
                TextField(label, text: $text)
                    .font(GolfrFonts.body())
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GolfrColors.backgroundCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(GolfrColors.textSecondary.opacity(0.15), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - All Rounds Sheet

struct AllRoundsSheet: View {
    @Environment(\.dismiss) var dismiss
    let rounds = Round.mocks

    var body: some View {
        NavigationStack {
            ZStack {
                GolfrColors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(rounds) { round in
                            RoundListItem(round: round)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("All Rounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GolfrColors.primary)
                }
            }
        }
    }
}
