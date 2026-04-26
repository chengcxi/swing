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
                ToolbarItem(placement: .principal) {
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
                    .environmentObject(appViewModel)
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = appViewModel.currentUser {
                    EditProfileSheet(user: user)
                        .environmentObject(appViewModel)
                }
            }
            .sheet(isPresented: $showAllRounds) {
                AllRoundsSheet()
                    .environmentObject(appViewModel)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openEditProfile)) { _ in
                showEditProfile = true
            }
        }
    }
}

// MARK: - Burger Menu Sheet

struct BurgerMenuSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showShareSheet = false
    @State private var confirmSignOut = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BurgerMenuItem(icon: "person.crop.circle", title: "Edit Profile") {
                        dismiss()
                        // ProfileView listens for this via NotificationCenter
                        NotificationCenter.default.post(name: .openEditProfile, object: nil)
                    }
                    BurgerMenuItem(icon: "person.2.fill", title: "Invite Friends") {
                        showShareSheet = true
                    }
                }

                Section {
                    BurgerMenuItem(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", tint: GolfrColors.error) {
                        confirmSignOut = true
                    }
                }
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
            .alert("Sign out?", isPresented: $confirmSignOut) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await appViewModel.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("You'll need to sign in again to use Golfr.")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: ["Join me on Golfr — track your rounds and find your crew. https://golfr.app"])
            }
        }
    }
}

// Notification used to bridge BurgerMenuSheet → ProfileView for the Edit Profile sheet
extension Notification.Name {
    static let openEditProfile = Notification.Name("openEditProfile")
}

// UIKit share sheet bridge
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct BurgerMenuItem: View {
    let icon: String
    let title: String
    var tint: Color = GolfrColors.primaryLight
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(tint)
                    .frame(width: 28)
                Text(title)
                    .font(GolfrFonts.body())
                    .foregroundColor(tint == GolfrColors.error ? GolfrColors.error : GolfrColors.textPrimary)
                Spacer()
                if tint != GolfrColors.error {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(GolfrColors.textSecondary)
                }
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
                                Image(systemName: "checkmark.circle.fill")
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
        .padding(.top, 24)
        .padding(.bottom, 30)
        .background(
            BannerShape()
                .fill(GolfrColors.cardGradient)
        )
        .shadow(color: GolfrColors.primary.opacity(0.25), radius: 8, x: 0, y: 4)
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
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var rounds: [Round] = []
    @State private var isLoading = false
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

            if isLoading && rounds.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if rounds.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "flag")
                        .font(.system(size: 28))
                        .foregroundColor(GolfrColors.textSecondary.opacity(0.4))
                    Text("No rounds yet")
                        .font(GolfrFonts.callout())
                        .foregroundColor(GolfrColors.textSecondary)
                    Text("Log a round to see it here.")
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textSecondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(rounds.prefix(5)) { round in
                    RoundListItem(round: round)
                        .padding(.horizontal)
                }
            }
        }
        .task(id: appViewModel.currentUser?.id) {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        rounds = await appViewModel.fetchRounds()
        isLoading = false
    }
}

struct RoundListItem: View {
    let round: Round

    var body: some View {
        Button(action: shareRound) {
            HStack(alignment: .top, spacing: 14) {
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

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GolfrColors.primaryLight)
                }
            }
            .padding(12)
            .golfrCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }

    private func shareRound() {
        UIApplication.shared.share(items: [
            "I shot \(round.score) at \(round.courseName) on Golfr ⛳️"
        ])
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
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var rounds: [Round] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                GolfrColors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if isLoading && rounds.isEmpty {
                            ProgressView().padding(.top, 60)
                        } else if rounds.isEmpty {
                            Text("No rounds logged yet")
                                .font(GolfrFonts.callout())
                                .foregroundColor(GolfrColors.textSecondary)
                                .padding(.top, 80)
                        }
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
            .task {
                isLoading = true
                rounds = await appViewModel.fetchRounds()
                isLoading = false
            }
        }
    }
}
