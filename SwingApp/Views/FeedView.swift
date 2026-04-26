import SwiftUI

struct FeedView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = FeedViewModel()
    @State private var showAddFriends = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        ProgressView()
                            .padding(.top, 80)
                    } else if viewModel.posts.isEmpty {
                        FeedEmptyState(onFindFriends: { showAddFriends = true })
                            .padding(.top, 80)
                            .padding(.horizontal)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                PostCard(post: post, viewModel: viewModel)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 2)
            }
            .refreshable {
                viewModel.fetchPosts()
            }
            .background(GolfrColors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("golfr")
                        .font(GolfrFonts.pageTitle(size: 26))
                        .foregroundColor(GolfrColors.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(GolfrColors.backgroundCard))
                        .fixedSize()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFriends = true }) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(GolfrColors.primary)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(GolfrColors.backgroundCard))
                            .overlay(Circle().stroke(GolfrColors.primary, lineWidth: 1.5))
                    }
                }
            }
            .sheet(isPresented: $showAddFriends) {
                AddFriendsSheet()
                    .environmentObject(appViewModel)
            }
        }
    }
}

// MARK: - Add Friends Sheet

@MainActor
class AddFriendsViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var searchResults: [User] = []
    @Published var suggestions: [User] = []
    @Published var followingIds: Set<UUID> = []
    @Published var isLoading = false

    weak var appViewModel: AppViewModel?

    private var searchTask: Task<Void, Never>?

    private var devSuggestions: [User] {
        // Static fake people so the sheet has something to render in devMode
        [
            User(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, username: "matt_g", fullName: "Matt Greene", isVerified: true, profileImageName: "", university: "UCLA", handicap: 4.2, averageScore: 78, bestRound: 71, roundsPlayed: 22, badges: [.verified], bio: "Weekend warrior", friendsCount: 14),
            User(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, username: "sarah_k", fullName: "Sarah Kim", isVerified: false, profileImageName: "", university: "USC", handicap: 12.7, averageScore: 88, bestRound: 79, roundsPlayed: 9, badges: [], bio: "Trying to break 80", friendsCount: 8),
            User(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, username: "jake_w", fullName: "Jake Wilson", isVerified: true, profileImageName: "", university: "Stanford", handicap: 1.8, averageScore: 73, bestRound: 67, roundsPlayed: 41, badges: [.verified, .top10], bio: "College team", friendsCount: 32),
            User(id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, username: "alex_t", fullName: "Alex Tran", isVerified: false, profileImageName: "", university: nil, handicap: 8.4, averageScore: 84, bestRound: 76, roundsPlayed: 18, badges: [], bio: nil, friendsCount: 5),
            User(id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!, username: "tom_r", fullName: "Tom Rivera", isVerified: false, profileImageName: "", university: "Cal", handicap: 15.0, averageScore: 92, bestRound: 84, roundsPlayed: 6, badges: [], bio: "Just started", friendsCount: 3),
        ]
    }

    func loadSuggestions() async {
        if appViewModel?.devMode == true {
            suggestions = devSuggestions
            // Reflect any in-memory follows from AppViewModel
            followingIds = Set(devSuggestions.map(\.id).filter { appViewModel?.isFollowingDev($0) == true })
            return
        }
        // Show recently-registered users that the current user isn't already following
        do {
            let profiles: [DBProfile] = try await supabase.from("profiles")
                .select()
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            let currentId = try? await supabase.auth.session.user.id
            suggestions = profiles
                .filter { $0.id != currentId }
                .map { $0.toUser() }

            await refreshFollowing()
        } catch {
            print("AddFriendsViewModel.loadSuggestions failed: \(error)")
        }
    }

    func search(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            searchResults = []
            return
        }
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            await self?.runSearch(trimmed)
        }
    }

    private func runSearch(_ query: String) async {
        isLoading = true
        defer { isLoading = false }

        if appViewModel?.devMode == true {
            // Filter the dev suggestion pool against the query
            let q = query.lowercased()
            searchResults = devSuggestions.filter {
                $0.username.lowercased().contains(q) || $0.fullName.lowercased().contains(q)
            }
            return
        }

        do {
            let pattern = "%\(query)%"
            let profiles: [DBProfile] = try await supabase.from("profiles")
                .select()
                .or("username.ilike.\(pattern),full_name.ilike.\(pattern)")
                .limit(25)
                .execute()
                .value

            let currentId = try? await supabase.auth.session.user.id
            searchResults = profiles
                .filter { $0.id != currentId }
                .map { $0.toUser() }
        } catch {
            print("AddFriendsViewModel.runSearch failed: \(error)")
            searchResults = []
        }
    }

    private func refreshFollowing() async {
        guard let currentId = try? await supabase.auth.session.user.id else { return }
        do {
            let follows: [DBFollow] = try await supabase.from("follows")
                .select()
                .eq("follower_id", value: currentId)
                .execute()
                .value
            followingIds = Set(follows.map { $0.followingId })
        } catch {
            print("AddFriendsViewModel.refreshFollowing failed: \(error)")
        }
    }

    func toggleFollow(_ user: User) async {
        if appViewModel?.devMode == true {
            appViewModel?.toggleFollowDev(user.id)
            if followingIds.contains(user.id) {
                followingIds.remove(user.id)
            } else {
                followingIds.insert(user.id)
            }
            return
        }
        guard let currentId = try? await supabase.auth.session.user.id else { return }
        let isFollowing = followingIds.contains(user.id)

        // Optimistic update
        if isFollowing {
            followingIds.remove(user.id)
        } else {
            followingIds.insert(user.id)
        }

        do {
            if isFollowing {
                try await supabase.from("follows")
                    .delete()
                    .eq("follower_id", value: currentId)
                    .eq("following_id", value: user.id)
                    .execute()
            } else {
                let follow = DBFollow(followerId: currentId, followingId: user.id)
                try await supabase.from("follows")
                    .insert(follow)
                    .execute()
            }
        } catch {
            // Revert on failure
            if isFollowing {
                followingIds.insert(user.id)
            } else {
                followingIds.remove(user.id)
            }
            print("AddFriendsViewModel.toggleFollow failed: \(error)")
        }
    }
}

// Helper to map DBProfile -> User in this file
fileprivate extension DBProfile {
    func toUser() -> User {
        User(
            id: id,
            username: username,
            fullName: fullName ?? username,
            isVerified: isUniversityVerified ?? false,
            profileImageName: avatarUrl ?? "",
            university: nil,
            handicap: handicap ?? 0.0,
            averageScore: 0.0,
            bestRound: 0,
            roundsPlayed: 0,
            badges: isUniversityVerified == true ? [.verified] : [],
            bio: bio,
            friendsCount: 0
        )
    }
}

struct AddFriendsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var vm = AddFriendsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                GolfrColors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Search bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(GolfrColors.textSecondary)
                            TextField("Search users...", text: $vm.query)
                                .font(GolfrFonts.body())
                                .autocapitalization(.none)
                                .autocorrectionDisabled(true)
                                .onChange(of: vm.query) { newValue in
                                    vm.search(newValue)
                                }
                            if !vm.query.isEmpty {
                                Button(action: { vm.query = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(GolfrColors.textSecondary)
                                }
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(GolfrColors.backgroundCard)
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if !vm.query.isEmpty {
                            sectionHeader("Search results")
                            usersList(vm.searchResults)
                        } else {
                            sectionHeader("Suggested for you")
                            usersList(vm.suggestions)
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Find friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GolfrColors.primary)
                }
            }
            .task {
                vm.appViewModel = appViewModel
                await vm.loadSuggestions()
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(GolfrFonts.caption())
            .foregroundColor(GolfrColors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal)
    }

    @ViewBuilder
    private func usersList(_ users: [User]) -> some View {
        if users.isEmpty {
            Text(vm.query.isEmpty ? "No suggestions yet." : "No users found.")
                .font(GolfrFonts.callout())
                .foregroundColor(GolfrColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
        } else {
            VStack(spacing: 10) {
                ForEach(users) { user in
                    AddFriendRow(
                        user: user,
                        isFollowing: vm.followingIds.contains(user.id)
                    ) {
                        Task { await vm.toggleFollow(user) }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct AddFriendRow: View {
    let user: User
    let isFollowing: Bool
    var onTapFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GolfrColors.primaryLight.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(user.fullName.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(GolfrColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(user.fullName)
                        .font(GolfrFonts.headline())
                        .foregroundColor(GolfrColors.textPrimary)
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(GolfrColors.primaryLight)
                    }
                }
                Text("@\(user.username)")
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            Spacer()

            Button(action: onTapFollow) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(GolfrFonts.caption())
                    .foregroundColor(isFollowing ? GolfrColors.textSecondary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(isFollowing ? GolfrColors.backgroundElevated : GolfrColors.primary)
                    )
            }
        }
        .padding(12)
        .golfrCard(cornerRadius: 14)
    }
}

// MARK: - Empty State

struct FeedEmptyState: View {
    var onFindFriends: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(GolfrColors.primary.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "flag.2.crossed")
                    .font(.system(size: 38))
                    .foregroundColor(GolfrColors.primary)
            }

            VStack(spacing: 6) {
                Text("Your feed is quiet")
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)
                Text("Follow friends or log a round to fill your feed.")
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Button(action: onFindFriends) {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Find friends")
                        .font(GolfrFonts.headline())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Capsule().fill(GolfrColors.primary))
            }
        }
    }
}
