import SwiftUI

struct PostCard: View {
    @State var post: Post
    @ObservedObject var viewModel: FeedViewModel
    @State private var showComments = false
    @State private var showOptions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(spacing: 10) {
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
                    }
                }

                Spacer()

                Button(action: { showOptions = true }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(GolfrColors.textSecondary)
                        .font(.system(size: 14))
                }
            }

            // Round info
            if let round = post.round {
                VStack(alignment: .leading, spacing: 8) {
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

            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textPrimary)
                    .lineSpacing(2)
            }

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
                    action: { showComments = true }
                )

                Spacer()

                Text(timeString(from: post.timestamp))
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)
            }
        }
        .padding(16)
        .golfrCard(cornerRadius: 20)
        .sheet(isPresented: $showComments) {
            CommentsSheet(postId: post.id, commentCount: $post.comments, viewModel: viewModel)
        }
        .confirmationDialog("Post options", isPresented: $showOptions, titleVisibility: .hidden) {
            Button("Copy link") {
                UIPasteboard.general.string = "golfr://post/\(post.id.uuidString)"
            }
            Button("Share…") {
                UIApplication.shared.share(items: ["Check out this round on Golfr — \(post.caption)"])
            }
            Button("Cancel", role: .cancel) {}
        }
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

// MARK: - Comments Sheet

struct CommentDisplayItem: Identifiable {
    let id: UUID
    let username: String
    let fullName: String
    let content: String
    let timestamp: Date
}

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [CommentDisplayItem] = []
    @Published var draft: String = ""
    @Published var isLoading = false
    @Published var isSending = false

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func load(postId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let rows: [DBComment] = try await supabase.from("comments")
                .select("*, profile:profiles(*)")
                .eq("round_id", value: postId)
                .order("created_at", ascending: true)
                .execute()
                .value

            comments = rows.map { row in
                let date = row.createdAt.flatMap { Self.iso.date(from: $0) } ?? Date()
                return CommentDisplayItem(
                    id: row.id,
                    username: row.profile?.username ?? "user",
                    fullName: row.profile?.fullName ?? row.profile?.username ?? "user",
                    content: row.content,
                    timestamp: date
                )
            }
        } catch {
            print("CommentsViewModel.load failed: \(error)")
        }
    }

    func send(postId: UUID) async -> Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        isSending = true
        defer { isSending = false }

        do {
            let userId = try await supabase.auth.session.user.id
            struct Insert: Encodable {
                let user_id: UUID
                let round_id: UUID
                let content: String
            }
            let row: DBComment = try await supabase.from("comments")
                .insert(Insert(user_id: userId, round_id: postId, content: trimmed))
                .select("*, profile:profiles(*)")
                .single()
                .execute()
                .value

            let date = row.createdAt.flatMap { Self.iso.date(from: $0) } ?? Date()
            comments.append(CommentDisplayItem(
                id: row.id,
                username: row.profile?.username ?? "you",
                fullName: row.profile?.fullName ?? row.profile?.username ?? "you",
                content: row.content,
                timestamp: date
            ))
            draft = ""
            return true
        } catch {
            print("CommentsViewModel.send failed: \(error)")
            return false
        }
    }
}

struct CommentsSheet: View {
    let postId: UUID
    @Binding var commentCount: Int
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = CommentsViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.isLoading && vm.comments.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if vm.comments.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 28))
                            .foregroundColor(GolfrColors.textSecondary.opacity(0.4))
                        Text("No comments yet")
                            .font(GolfrFonts.headline())
                            .foregroundColor(GolfrColors.textPrimary)
                        Text("Be the first to leave a comment.")
                            .font(GolfrFonts.caption())
                            .foregroundColor(GolfrColors.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(vm.comments) { c in
                                CommentRow(comment: c)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    TextField("Add a comment…", text: $vm.draft, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($inputFocused)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(GolfrColors.backgroundElevated)
                        )

                    Button(action: send) {
                        if vm.isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(canSend ? GolfrColors.primary : GolfrColors.textSecondary.opacity(0.4))
                        }
                    }
                    .disabled(!canSend || vm.isSending)
                }
                .padding(12)
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GolfrColors.primary)
                }
            }
            .task { await vm.load(postId: postId) }
        }
    }

    private var canSend: Bool {
        !vm.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        Task {
            let ok = await vm.send(postId: postId)
            if ok {
                commentCount += 1
                inputFocused = true
            }
        }
    }
}

struct CommentRow: View {
    let comment: CommentDisplayItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(GolfrColors.primaryLight.opacity(0.12))
                    .frame(width: 34, height: 34)
                Text(comment.fullName.prefix(1).uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(GolfrColors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("@\(comment.username)")
                        .font(GolfrFonts.headline())
                        .foregroundColor(GolfrColors.textPrimary)
                    Text(timeString(from: comment.timestamp))
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textSecondary)
                }
                Text(comment.content)
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textPrimary)
            }

            Spacer()
        }
    }

    private func timeString(from date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - UIApplication share helper

extension UIApplication {
    func share(items: [Any]) {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(activity, animated: true)
    }
}
