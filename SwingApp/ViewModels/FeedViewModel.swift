import Foundation
import Combine

class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchPosts()
    }
    
    func fetchPosts() {
        APIService.shared.fetchPosts()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error): print("Error fetching posts: \(error)")
                }
            }, receiveValue: { [weak self] posts in
                self?.posts = posts
            })
            .store(in: &cancellables)
    }
    
    func likePost(postId: UUID) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLiked.toggle()
            posts[index].likes += posts[index].isLiked ? 1 : -1
        }
    }
    
    func addComment(postId: UUID, comment: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].comments += 1
        }
    }
}
