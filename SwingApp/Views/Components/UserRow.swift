import SwiftUI

struct UserRow: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let user: User
    @State private var isFollowing: Bool? = nil
    @State private var inFlight = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GolfrColors.primaryLight.opacity(0.1))
                    .frame(width: 44, height: 44)

                Text(user.fullName.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(GolfrColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(user.fullName)
                        .font(GolfrFonts.headline())
                        .foregroundColor(GolfrColors.textPrimary)

                    if user.isVerified {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(GolfrColors.primaryLight)
                    }
                }

                Text("@\(user.username)")
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            Spacer()

            Button(action: toggleFollow) {
                Group {
                    if inFlight {
                        ProgressView()
                            .frame(width: 60, height: 16)
                    } else {
                        Text(buttonLabel)
                            .font(GolfrFonts.caption())
                            .foregroundColor(isFollowing == true ? GolfrColors.textSecondary : .white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isFollowing == true ? GolfrColors.backgroundElevated : GolfrColors.primaryLight)
                )
            }
            .disabled(inFlight)
        }
        .padding(12)
        .golfrCard(cornerRadius: 12)
        .task { await checkFollowStatus() }
    }

    private var buttonLabel: String {
        switch isFollowing {
        case .some(true): return "Following"
        case .some(false): return "Follow"
        case .none: return "Follow"
        }
    }

    private func checkFollowStatus() async {
        if appViewModel.devMode {
            isFollowing = appViewModel.isFollowingDev(user.id)
            return
        }
        guard let me = try? await supabase.auth.session.user.id else { return }
        do {
            let rows: [DBFollow] = try await supabase.from("follows")
                .select()
                .eq("follower_id", value: me)
                .eq("following_id", value: user.id)
                .limit(1)
                .execute()
                .value
            isFollowing = !rows.isEmpty
        } catch {
            isFollowing = false
        }
    }

    private func toggleFollow() {
        guard !inFlight else { return }

        if appViewModel.devMode {
            appViewModel.toggleFollowDev(user.id)
            isFollowing = appViewModel.isFollowingDev(user.id)
            return
        }

        inFlight = true
        Task {
            defer { Task { @MainActor in inFlight = false } }
            guard let me = try? await supabase.auth.session.user.id else { return }
            do {
                if isFollowing == true {
                    try await supabase.from("follows")
                        .delete()
                        .eq("follower_id", value: me)
                        .eq("following_id", value: user.id)
                        .execute()
                    isFollowing = false
                } else {
                    let follow = DBFollow(followerId: me, followingId: user.id)
                    try await supabase.from("follows")
                        .insert(follow)
                        .execute()
                    isFollowing = true
                }
            } catch {
                print("UserRow.toggleFollow failed: \(error)")
            }
        }
    }
}
