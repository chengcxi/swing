import SwiftUI

struct PostDetailView: View {
    @ObservedObject var feedViewModel: FeedViewModel
    let post: Post
    @State private var commentText = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Post Content
                HStack {
                    AsyncImage(url: URL(string: post.authorAvatar)) { image in
                        image.resizable()
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(post.author).bold()
                        Text(post.authorUsername).font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    Text(post.timestamp).font(.caption).foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                Text(post.content)
                    .padding(.horizontal)
                
                if let image = post.image {
                    AsyncImage(url: URL(string: image)) { img in
                        img.resizable().scaledToFit()
                    } placeholder: {
                        Color.gray.frame(height: 200)
                    }
                }
                
                if let roundId = post.roundId {
                    // Linked Round View (Simplified)
                    HStack {
                        Image(systemName: "flag.fill").foregroundColor(.green)
                        Text("Played a round")
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Actions
                HStack(spacing: 20) {
                    Button {
                        feedViewModel.toggleLike(post: post)
                    } label: {
                        HStack {
                            Image(systemName: "heart")
                            Text("\(post.likes)")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                    }
                }
                .padding(.horizontal)
                .foregroundColor(.gray)
                
                Divider()
                
                // Comments Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comments").font(.headline)
                    
                    ForEach(post.commentsList) { comment in
                        HStack(alignment: .top) {
                            AsyncImage(url: URL(string: comment.authorAvatar)) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(comment.authorName).bold().font(.caption)
                                Text(comment.text).font(.body)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                TextField("Add a comment...", text: $commentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Post") {
                    feedViewModel.addComment(post: post, text: commentText)
                    commentText = ""
                }
                .disabled(commentText.isEmpty)
            }
            .padding()
            .background(Color.white)
            .shadow(radius: 2)
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }
}
