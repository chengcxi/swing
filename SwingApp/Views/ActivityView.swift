import SwiftUI

// MARK: - Activity Item Model

struct ActivityItem: Identifiable {
    let id = UUID()
    let type: ActivityType
    let username: String
    let message: String
    let timestamp: Date
    var isRead: Bool

    enum ActivityType {
        case like
        case comment
        case follow
        case achievement
        case friendRequest

        var icon: String {
            switch self {
            case .like: return "heart.fill"
            case .comment: return "bubble.right.fill"
            case .follow: return "person.badge.plus"
            case .achievement: return "trophy.fill"
            case .friendRequest: return "person.2.fill"
            }
        }

        var color: Color {
            switch self {
            case .like: return GolfrColors.primaryLight
            case .comment: return GolfrColors.primaryMedium
            case .follow: return GolfrColors.primaryLight
            case .achievement: return GolfrColors.primary
            case .friendRequest: return GolfrColors.primaryLight
            }
        }
    }

    static let mocks: [ActivityItem] = [
        .init(type: .achievement, username: "golfr", message: "You earned the \"Top 10\" badge!", timestamp: Date().addingTimeInterval(-300), isRead: false),
        .init(type: .friendRequest, username: "sarah_k", message: "wants to be your friend", timestamp: Date().addingTimeInterval(-1200), isRead: false),
        .init(type: .like, username: "matt_g", message: "liked your round at Sandpiper Golf Club", timestamp: Date().addingTimeInterval(-1800), isRead: false),
        .init(type: .comment, username: "sarah_k", message: "commented: \"Nice round! What driver are you using?\"", timestamp: Date().addingTimeInterval(-3600), isRead: false),
        .init(type: .friendRequest, username: "mike_j", message: "wants to be your friend", timestamp: Date().addingTimeInterval(-5400), isRead: true),
        .init(type: .follow, username: "jake_w", message: "started following you", timestamp: Date().addingTimeInterval(-7200), isRead: true),
        .init(type: .like, username: "alex_t", message: "liked your round at Riviera Country Club", timestamp: Date().addingTimeInterval(-90000), isRead: true),
        .init(type: .comment, username: "tom_r", message: "commented: \"Let's play a round together!\"", timestamp: Date().addingTimeInterval(-172800), isRead: true),
    ]
}

// MARK: - Activity View

struct ActivityView: View {
    @State private var activities = ActivityItem.mocks

    var unreadActivities: [ActivityItem] {
        activities.filter { !$0.isRead }
    }

    var readActivities: [ActivityItem] {
        activities.filter { $0.isRead }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // New section
                    if !unreadActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("New")
                                .font(GolfrFonts.caption())
                                .foregroundColor(GolfrColors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.horizontal)

                            ForEach(unreadActivities) { activity in
                                ActivityRow(activity: activity)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Earlier section
                    if !readActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Earlier")
                                .font(GolfrFonts.caption())
                                .foregroundColor(GolfrColors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.horizontal)

                            ForEach(readActivities) { activity in
                                ActivityRow(activity: activity)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 2)
            }
            .background(GolfrColors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("activity")
                        .font(GolfrFonts.pageTitle())
                        .foregroundColor(GolfrColors.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(GolfrColors.backgroundCard))
                        .fixedSize()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !unreadActivities.isEmpty {
                        GolfrNavButton(icon: "checkmark.circle") {
                            withAnimation {
                                activities = activities.map { item in
                                    var copy = item
                                    copy.isRead = true
                                    return copy
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: ActivityItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(activity.type.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: activity.type.icon)
                        .font(.system(size: 16))
                        .foregroundColor(activity.type.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.username)
                        .font(GolfrFonts.headline())
                        .foregroundColor(GolfrColors.textPrimary)

                    Text(activity.message)
                        .font(GolfrFonts.body())
                        .foregroundColor(GolfrColors.textSecondary)
                        .lineLimit(2)

                    Text(timeString(from: activity.timestamp))
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textSecondary.opacity(0.7))
                        .padding(.top, 2)
                }

                Spacer()

                // Unread indicator (non-friend-request only)
                if activity.type != .friendRequest && !activity.isRead {
                    Circle()
                        .fill(GolfrColors.primaryLight)
                        .frame(width: 8, height: 8)
                }
            }

            // Friend request: accept/decline buttons below content
            if activity.type == .friendRequest {
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Text("Accept")
                            .font(GolfrFonts.caption())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(GolfrColors.primaryLight))
                    }

                    Button(action: {}) {
                        Text("Decline")
                            .font(GolfrFonts.caption())
                            .foregroundColor(GolfrColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(GolfrColors.backgroundElevated))
                    }
                }
                .padding(.leading, 56)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(activity.isRead ? GolfrColors.backgroundCard : GolfrColors.primary.opacity(0.04))
        )
        .golfrCard(cornerRadius: 16)
    }

    func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
