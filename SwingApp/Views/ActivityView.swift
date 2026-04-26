import SwiftUI

// MARK: - Activity Item Model

struct ActivityItem: Identifiable {
    let id: String
    let type: ActivityType
    let username: String
    let message: String
    let timestamp: Date
    var isRead: Bool

    enum ActivityType {
        case like
        case comment
        case follow
        case friendRequest

        var icon: String {
            switch self {
            case .like: return "heart.fill"
            case .comment: return "bubble.right.fill"
            case .follow: return "person.badge.plus"
            case .friendRequest: return "person.2.fill"
            }
        }

        var color: Color {
            switch self {
            case .like: return GolfrColors.primaryLight
            case .comment: return GolfrColors.primaryMedium
            case .follow: return GolfrColors.primaryLight
            case .friendRequest: return GolfrColors.primaryLight
            }
        }
    }
}

// MARK: - Activity Loader

@MainActor
class ActivityLoader: ObservableObject {
    @Published var activities: [ActivityItem] = []
    @Published var isLoading = false

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static func parseDate(_ raw: String?) -> Date {
        guard let raw = raw else { return Date() }
        if let d = iso.date(from: raw) { return d }
        // Fall back to non-fractional ISO8601
        let plain = ISO8601DateFormatter()
        return plain.date(from: raw) ?? Date()
    }

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        async let likes = fetchLikes(userId: userId)
        async let comments = fetchComments(userId: userId)
        async let follows = fetchFollows(userId: userId)

        let combined = await (likes + comments + follows)
        activities = combined.sorted(by: { $0.timestamp > $1.timestamp })
    }

    private func fetchLikes(userId: UUID) async -> [ActivityItem] {
        struct LikeRow: Decodable {
            let createdAt: String?
            let user: DBProfile?
            let round: RoundLite?

            struct RoundLite: Decodable {
                let course: CourseLite?

                struct CourseLite: Decodable {
                    let name: String
                }
            }

            enum CodingKeys: String, CodingKey {
                case createdAt = "created_at"
                case user
                case round
            }
        }

        do {
            let rows: [LikeRow] = try await supabase.from("likes")
                .select("created_at, user:profiles!likes_user_id_fkey(*), round:rounds!inner(user_id, course:golf_courses(name))")
                .eq("round.user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            return rows.compactMap { row in
                guard let user = row.user else { return nil }
                let courseName = row.round?.course?.name ?? "your round"
                let ts = Self.parseDate(row.createdAt)
                return ActivityItem(
                    id: "like-\(user.id.uuidString)-\(row.createdAt ?? "")",
                    type: .like,
                    username: user.username,
                    message: "liked your round at \(courseName)",
                    timestamp: ts,
                    isRead: false
                )
            }
        } catch {
            print("ActivityLoader.fetchLikes failed: \(error)")
            return []
        }
    }

    private func fetchComments(userId: UUID) async -> [ActivityItem] {
        struct CommentRow: Decodable {
            let createdAt: String?
            let content: String
            let user: DBProfile?
            let round: RoundLite?

            struct RoundLite: Decodable {
                let userId: UUID

                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                }
            }

            enum CodingKeys: String, CodingKey {
                case createdAt = "created_at"
                case content
                case user
                case round
            }
        }

        do {
            let rows: [CommentRow] = try await supabase.from("comments")
                .select("created_at, content, user:profiles!comments_user_id_fkey(*), round:rounds!inner(user_id)")
                .eq("round.user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            return rows.compactMap { row in
                guard let user = row.user else { return nil }
                let snippet = row.content.count > 80
                    ? String(row.content.prefix(80)) + "…"
                    : row.content
                let ts = Self.parseDate(row.createdAt)
                return ActivityItem(
                    id: "comment-\(user.id.uuidString)-\(row.createdAt ?? "")",
                    type: .comment,
                    username: user.username,
                    message: "commented: \"\(snippet)\"",
                    timestamp: ts,
                    isRead: false
                )
            }
        } catch {
            print("ActivityLoader.fetchComments failed: \(error)")
            return []
        }
    }

    private func fetchFollows(userId: UUID) async -> [ActivityItem] {
        struct FollowRow: Decodable {
            let createdAt: String?
            let follower: DBProfile?

            enum CodingKeys: String, CodingKey {
                case createdAt = "created_at"
                case follower
            }
        }

        do {
            let rows: [FollowRow] = try await supabase.from("follows")
                .select("created_at, follower:profiles!follows_follower_id_fkey(*)")
                .eq("following_id", value: userId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            return rows.compactMap { row in
                guard let follower = row.follower else { return nil }
                let ts = Self.parseDate(row.createdAt)
                return ActivityItem(
                    id: "follow-\(follower.id.uuidString)",
                    type: .follow,
                    username: follower.username,
                    message: "started following you",
                    timestamp: ts,
                    isRead: false
                )
            }
        } catch {
            print("ActivityLoader.fetchFollows failed: \(error)")
            return []
        }
    }
}

// MARK: - Activity View

struct ActivityView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var loader = ActivityLoader()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if loader.isLoading && loader.activities.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else if loader.activities.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 36))
                                .foregroundColor(GolfrColors.textSecondary.opacity(0.4))
                            Text("No activity yet")
                                .font(GolfrFonts.headline())
                                .foregroundColor(GolfrColors.textPrimary)
                            Text("Likes, comments, and follows will show up here.")
                                .font(GolfrFonts.body())
                                .foregroundColor(GolfrColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent")
                                .font(GolfrFonts.caption())
                                .foregroundColor(GolfrColors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.horizontal)

                            ForEach(loader.activities) { activity in
                                ActivityRow(activity: activity)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 2)
            }
            .refreshable {
                if let id = appViewModel.currentUser?.id {
                    await loader.load(userId: id)
                }
            }
            .background(GolfrColors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("activity")
                        .font(GolfrFonts.pageTitle())
                        .foregroundColor(GolfrColors.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(GolfrColors.backgroundCard))
                        .fixedSize()
                }
            }
            .task(id: appViewModel.currentUser?.id) {
                if let id = appViewModel.currentUser?.id {
                    await loader.load(userId: id)
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
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: activity.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(activity.type.color)
            }

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
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(GolfrColors.backgroundCard)
        )
        .golfrCard(cornerRadius: 16)
    }

    func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
