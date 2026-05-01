import Foundation
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchPosts()
    }

    func fetchPosts() {
        isLoading = true
        APIService.shared.fetchPosts()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("FeedViewModel.fetchPosts failed: \(error)")
                }
            }, receiveValue: { [weak self] posts in
                self?.posts = posts
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }

    func likePost(postId: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        let wasLiked = posts[index].isLiked
        posts[index].isLiked = !wasLiked
        posts[index].likes += wasLiked ? -1 : 1

        Task {
            do {
                if wasLiked {
                    try await supabase.from("likes")
                        .delete()
                        .eq("round_id", value: postId)
                        .eq("user_id", value: try await supabase.auth.session.user.id)
                        .execute()
                } else {
                    let userId = try await supabase.auth.session.user.id
                    let like = DBLike(userId: userId, roundId: postId)
                    try await supabase.from("likes")
                        .insert(like)
                        .execute()
                }
            } catch {
                // Revert optimistic update on failure
                await MainActor.run {
                    if let i = self.posts.firstIndex(where: { $0.id == postId }) {
                        self.posts[i].isLiked = wasLiked
                        self.posts[i].likes += wasLiked ? 1 : -1
                    }
                }
                print("FeedViewModel.likePost failed: \(error)")
            }
        }
    }

    func addComment(postId: UUID, comment: String) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        posts[index].comments += 1

        Task {
            do {
                let userId = try await supabase.auth.session.user.id
                struct CommentInsert: Encodable {
                    let user_id: UUID
                    let round_id: UUID
                    let content: String
                }
                try await supabase.from("comments")
                    .insert(CommentInsert(user_id: userId, round_id: postId, content: comment))
                    .execute()
            } catch {
                await MainActor.run {
                    if let i = self.posts.firstIndex(where: { $0.id == postId }) {
                        self.posts[i].comments -= 1
                    }
                }
                print("FeedViewModel.addComment failed: \(error)")
            }
        }
    }
}
