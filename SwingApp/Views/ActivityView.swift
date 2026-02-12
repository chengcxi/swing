import SwiftUI

// MARK: - Activity Item Model

struct ActivityItem: Identifiable {
    let id = UUID()
    let type: ActivityType
    let username: String
    let message: String
    let timestamp: Date
    let isRead: Bool

    enum ActivityType {
        case like
        case comment
        case follow
        case achievement
        case streak

        var icon: String {
            switch self {
            case .like: return "heart.fill"
            case .comment: return "bubble.right.fill"
            case .follow: return "person.badge.plus"
            case .achievement: return "trophy.fill"
            case .streak: return "flame.fill"
            }
        }

        var color: Color {
            switch self {
            case .like: return GolfrColors.error
            case .comment: return GolfrColors.info
            case .follow: return GolfrColors.primaryLight
            case .achievement: return GolfrColors.gold
            case .streak: return GolfrColors.warning
            }
        }
    }

    static let mocks: [ActivityItem] = [
        .init(type: .achievement, username: "golfr", message: "You earned the \"Top 10\" badge!", timestamp: Date().addingTimeInterval(-300), isRead: false),
        .init(type: .like, username: "matt_g", message: "liked your round at Sandpiper Golf Club", timestamp: Date().addingTimeInterval(-1800), isRead: false),
        .init(type: .comment, username: "sarah_k", message: "commented: \"Nice round! What driver are you using?\"", timestamp: Date().addingTimeInterval(-3600), isRead: false),
        .init(type: .follow, username: "jake_w", message: "started following you", timestamp: Date().addingTimeInterval(-7200), isRead: true),
        .init(type: .streak, username: "golfr", message: "You're on a 3-day streak! Keep it up!", timestamp: Date().addingTimeInterval(-86400), isRead: true),
        .init(type: .like, username: "alex_t", message: "liked your round at Riviera Country Club", timestamp: Date().addingTimeInterval(-90000), isRead: true),
        .init(type: .comment, username: "tom_r", message: "commented: \"Let's play a round together!\"", timestamp: Date().addingTimeInterval(-172800), isRead: true),
        .init(type: .follow, username: "emily_c", message: "started following you", timestamp: Date().addingTimeInterval(-259200), isRead: true),
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
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // New section
                    if !unreadActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("New")
                                .font(GolfrFonts.callout())
                                .foregroundColor(GolfrColors.textSecondary)
                                .padding(.horizontal)

                            ForEach(unreadActivities) { activity in
                                ActivityRow(activity: activity)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Earlier section
                    if !readActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Earlier")
                                .font(GolfrFonts.callout())
                                .foregroundColor(GolfrColors.textSecondary)
                                .padding(.horizontal)

                            ForEach(readActivities) { activity in
                                ActivityRow(activity: activity)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(GolfrColors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Activity")
                        .font(GolfrFonts.title())
                        .foregroundColor(GolfrColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !unreadActivities.isEmpty {
                        Button(action: {
                            withAnimation {
                                activities = activities.map { item in
                                    var mutable = item
                                    // Can't mutate let, so we rebuild
                                    return ActivityItem(type: item.type, username: item.username, message: item.message, timestamp: item.timestamp, isRead: true)
                                }
                            }
                        }) {
                            Text("Read All")
                                .font(GolfrFonts.caption())
                                .foregroundColor(GolfrColors.primaryLight)
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
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 0) {
                    Text(activity.username)
                        .font(GolfrFonts.headline())
                        .foregroundColor(GolfrColors.textPrimary)
                    Text(" ")
                    Text(activity.message)
                        .font(GolfrFonts.body())
                        .foregroundColor(GolfrColors.textSecondary)
                }
                .lineLimit(2)

                Text(timeString(from: activity.timestamp))
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary.opacity(0.7))
            }

            Spacer()

            // Unread indicator
            if !activity.isRead {
                Circle()
                    .fill(GolfrColors.primaryLight)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(activity.isRead ? GolfrColors.backgroundCard : GolfrColors.primary.opacity(0.04))
        )
        .golfrCard(cornerRadius: 14)
    }

    func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
