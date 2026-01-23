import SwiftUI
import Combine

class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    
    init() {
        loadPosts()
    }
    
    func loadPosts() {
        // Mock data
        self.posts = [
            Post(
                id: 1,
                author: "Tiger Woods",
                authorUsername: "@tigerwoods",
                authorAvatar: "https://via.placeholder.com/150",
                timestamp: "2h ago",
                content: "Great day at the Masters!",
                image: "https://via.placeholder.com/400x300",
                likes: 1200,
                comments: 45,
                taggedUsers: nil,
                taggedCourses: ["Augusta National"]
            ),
             Post(
                id: 2,
                author: "Rory McIlroy",
                authorUsername: "@rory",
                authorAvatar: "https://via.placeholder.com/150",
                timestamp: "5h ago",
                content: "Practice makes perfect.",
                image: nil,
                likes: 800,
                comments: 20,
                taggedUsers: nil,
                taggedCourses: nil
            )
        ]
    }
    
    func addPost(content: String, round: GolfRound? = nil) {
        let newPost = Post(
            id: (posts.first?.id ?? 0) + 1,
            author: "John Doe",
            authorUsername: "@johndoe",
            authorAvatar: "https://via.placeholder.com/150",
            timestamp: "Just now",
            content: content,
            image: nil,
            likes: 0,
            comments: 0,
            taggedUsers: nil,
            taggedCourses: round != nil ? [round!.courseName] : nil,
            roundId: round?.id
        )
        posts.insert(newPost, at: 0)
    }
    
    func toggleLike(post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // Toggle logic mocked for current user
            // In real app check if currentUser ID is in likesList
            // For now just increment/decrement
             posts[index].likes += 1
        }
    }
    
    func addComment(post: Post, text: String) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            let comment = Comment(
                id: UUID(),
                authorId: "1", // Current User ID
                authorName: "John",
                authorAvatar: "https://via.placeholder.com/150",
                text: text,
                timestamp: Date()
            )
            posts[index].commentsList.append(comment)
            posts[index].comments += 1
        }
    }
}
