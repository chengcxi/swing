import Foundation
import Combine
import Supabase

class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
             await fetchPosts()
        }
    }
    
    @MainActor
    func fetchPosts() async {
        do {
            self.posts = try await DataService.shared.fetchPosts()
        } catch {
            print("Error fetching posts: \(error)")
        }
    }
    
    func likePost(postId: UUID) {
        // Optimistic update
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLiked = !(posts[index].isLiked ?? false)
            posts[index].likesCount = (posts[index].likesCount ?? 0) + (posts[index].isLiked! ? 1 : -1)
            
            Task {
                do {
                    if posts[index].isLiked == true {
                        try await DataService.shared.likePost(postId: postId)
                    } else {
                        try await DataService.shared.unlikePost(postId: postId)
                    }
                } catch {
                    print("Error toggling like: \(error)")
                }
            }
        }
    }
    
    func addComment(postId: UUID, comment: String) {
        Task {
            do {
                try await DataService.shared.addComment(postId: postId, text: comment)
                await fetchPosts()
            } catch {
                print("Error adding comment: \(error)")
            }
        }
    }
}
