import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        PostRow(post: post, viewModel: viewModel)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("golfr")
            .background(Color(white: 0.95)) // Light gray background
        }
    }
}
