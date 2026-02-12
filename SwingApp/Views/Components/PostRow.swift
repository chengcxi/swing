import SwiftUI

// Legacy PostRow kept as a typealias to PostCard for backwards compatibility
// New implementation is PostCard in FeedView.swift

struct PostCard: View {
    @State var post: Post
    @ObservedObject var viewModel: FeedViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(spacing: 10) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(GolfrColors.primaryMedium.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Text(post.user.username.prefix(1).uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(GolfrColors.primaryMedium)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.user.fullName)
                            .font(GolfrFonts.headline())
                            .foregroundColor(GolfrColors.textPrimary)
                        if post.user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(GolfrColors.primaryLight)
                        }
                    }
                    Text("@\(post.user.username)")
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textSecondary)
                }

                Spacer()

                Text(timeString(from: post.timestamp))
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(GolfrColors.textSecondary)
                        .font(.system(size: 14))
                }
            }

            // Round score card (Phantom-wallet-style dark card)
            if let round = post.round {
                RoundScoreCard(round: round)
            }

            // Caption
            Text(post.caption)
                .font(GolfrFonts.body())
                .foregroundColor(GolfrColors.textPrimary)
                .lineSpacing(2)

            // Action bar
            HStack(spacing: 0) {
                ActionButton(
                    icon: post.isLiked ? "heart.fill" : "heart",
                    count: post.likes,
                    color: post.isLiked ? GolfrColors.error : GolfrColors.textSecondary,
                    action: { viewModel.likePost(postId: post.id) }
                )

                ActionButton(
                    icon: "bubble.right",
                    count: post.comments,
                    color: GolfrColors.textSecondary,
                    action: {}
                )

                ActionButton(
                    icon: "arrow.2.squarepath",
                    count: 0,
                    color: GolfrColors.textSecondary,
                    action: {}
                )

                Spacer()

                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 16))
                        .foregroundColor(GolfrColors.textSecondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .golfrCard(cornerRadius: 20)
    }

    func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Round Score Card (Phantom-style dark card)

struct RoundScoreCard: View {
    let round: Round

    var body: some View {
        HStack(spacing: 14) {
            // Score circle
            ZStack {
                Circle()
                    .fill(GolfrColors.cream.opacity(0.15))
                    .frame(width: 64, height: 64)

                Circle()
                    .stroke(GolfrColors.cream.opacity(0.3), lineWidth: 2)
                    .frame(width: 64, height: 64)

                VStack(spacing: 0) {
                    Text("\(round.score)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(GolfrColors.cream)
                    Text("score")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(GolfrColors.textOnDarkMuted)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(round.courseName)
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.cream)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                        Text(round.location)
                            .font(GolfrFonts.caption())
                    }
                    .foregroundColor(GolfrColors.textOnDarkMuted)

                    HStack(spacing: 4) {
                        Image(systemName: "flag")
                            .font(.system(size: 10))
                        Text("\(round.holes) holes")
                            .font(GolfrFonts.caption())
                    }
                    .foregroundColor(GolfrColors.textOnDarkMuted)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(GolfrColors.textOnDarkMuted)
        }
        .padding(16)
        .golfrDarkCard()
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let count: Int
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                if count > 0 {
                    Text("\(count)")
                        .font(GolfrFonts.caption())
                }
            }
            .foregroundColor(color)
            .frame(minWidth: 60, alignment: .leading)
        }
    }
}
