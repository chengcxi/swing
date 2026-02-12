import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var showWelcomeBanner = true

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Welcome streak banner (Duolingo-style)
                    if showWelcomeBanner {
                        WelcomeBanner(onDismiss: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showWelcomeBanner = false
                            }
                        })
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Stories / Quick stats row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            YourRoundBubble()

                            ForEach(0..<5, id: \.self) { i in
                                StoryBubble(
                                    initial: ["M", "S", "J", "A", "T"][i],
                                    name: ["Matt", "Sarah", "Jake", "Alex", "Tom"][i],
                                    hasNew: i < 3
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 4)

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
                .padding(.top, 8)
            }
            .background(GolfrColors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("golfr")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(GolfrColors.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(GolfrColors.textPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Welcome Banner (Duolingo-style streak)

struct WelcomeBanner: View {
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(GolfrColors.gold.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundColor(GolfrColors.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("3-day streak!")
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)
                Text("Keep playing to maintain your streak")
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(GolfrColors.textSecondary)
                    .padding(6)
                    .background(Circle().fill(GolfrColors.backgroundElevated))
            }
        }
        .padding(14)
        .golfrCard(cornerRadius: 16)
    }
}

// MARK: - Story Bubbles

struct YourRoundBubble: View {
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(
                        GolfrColors.heroGradient,
                        lineWidth: 2.5
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(GolfrColors.primary)
            }
            Text("Your Round")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(GolfrColors.textSecondary)
        }
    }
}

struct StoryBubble: View {
    let initial: String
    let name: String
    let hasNew: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if hasNew {
                    Circle()
                        .strokeBorder(GolfrColors.heroGradient, lineWidth: 2.5)
                        .frame(width: 60, height: 60)
                } else {
                    Circle()
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 2)
                        .frame(width: 60, height: 60)
                }

                Circle()
                    .fill(GolfrColors.primaryMedium.opacity(0.15))
                    .frame(width: 52, height: 52)

                Text(initial)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(GolfrColors.primaryMedium)
            }
            Text(name)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(GolfrColors.textSecondary)
        }
    }
}
