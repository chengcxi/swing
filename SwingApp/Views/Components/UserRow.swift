import SwiftUI

struct UserRow: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let user: User
    @State private var friendRequested = false

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
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

            Button(action: {
                if !friendRequested {
                    Task {
                        await appViewModel.addFriend(userId: user.id)
                        friendRequested = true
                    }
                }
            }) {
                Text(friendRequested ? "Added" : "Add Friend")
                    .font(GolfrFonts.caption())
                    .foregroundColor(friendRequested ? GolfrColors.textSecondary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(friendRequested ? GolfrColors.backgroundElevated : GolfrColors.primaryLight)
                    )
            }
        }
        .padding(12)
        .golfrCard(cornerRadius: 12)
    }
}
