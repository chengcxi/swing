import SwiftUI

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
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(GolfrColors.primary)
                        }
                        Button(action: {}) {
                            Image(systemName: "star")
                                .font(.system(size: 12))
                                .foregroundColor(GolfrColors.textSecondary)
                        }
                    }
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(GolfrColors.textSecondary)
                        .font(.system(size: 14))
                }
            }

            // Round info as clean text card
            if let round = post.round {
                VStack(alignment: .leading, spacing: 8) {
                    // "@username shot a 80 at Course Name"
                    (
                        Text("@\(post.user.username)")
                            .font(GolfrFonts.headline())
                            .foregroundColor(GolfrColors.textPrimary)
                        + Text(" shot a ")
                            .font(GolfrFonts.body())
                            .foregroundColor(GolfrColors.textSecondary)
                        + Text("\(round.score)")
                            .font(GolfrFonts.headline())
                            .foregroundColor(GolfrColors.primary)
                        + Text(" at ")
                            .font(GolfrFonts.body())
                            .foregroundColor(GolfrColors.textSecondary)
                        + Text(round.courseName)
                            .font(GolfrFonts.headline())
                            .foregroundColor(GolfrColors.primaryLight)
                    )

                    Text(round.location)
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textPrimary)
                    .lineSpacing(2)
            }

            // Divider
            Rectangle()
                .fill(GolfrColors.textSecondary.opacity(0.15))
                .frame(height: 0.5)

            // Action bar
            HStack(spacing: 0) {
                ActionButton(
                    icon: post.isLiked ? "heart.fill" : "heart",
                    count: post.likes,
                    color: post.isLiked ? GolfrColors.error : GolfrColors.textSecondary,
                    action: { viewModel.likePost(postId: post.id) }
                )

                ActionButton(
                    icon: "message",
                    count: post.comments,
                    color: GolfrColors.textSecondary,
                    action: {}
                )

                Spacer()

                Text(timeString(from: post.timestamp))
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)
            }
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
