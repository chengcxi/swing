import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    
    @State private var showCreatePost = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                         NavigationLink(destination: PostDetailView(feedViewModel: viewModel, post: post)) {
                            PostView(post: post)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Feed")
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(feedViewModel: viewModel)
            }
        }
    }
}
