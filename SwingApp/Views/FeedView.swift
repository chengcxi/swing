import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Posts
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            PostCard(post: post, viewModel: viewModel)
                                .padding(.horizontal)
                        }
                    }

                    // Bottom spacer for tab bar
                    Spacer().frame(height: 100)
                }
                .padding(.top, 2)
            }
            .background(GolfrColors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("golfr")
                        .font(GolfrFonts.pageTitle(size: 26))
                        .foregroundColor(GolfrColors.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(GolfrColors.backgroundCard))
                        .fixedSize()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(GolfrColors.primary)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(GolfrColors.backgroundCard)
                            )
                            .overlay(
                                Circle()
                                    .stroke(GolfrColors.primary, lineWidth: 1.5)
                            )
                    }
                }
            }
        }
    }
}
