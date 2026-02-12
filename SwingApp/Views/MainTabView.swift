import SwiftUI

enum Tab: Int, CaseIterable {
    case feed
    case discover
    case addRound
    case activity
    case profile

    var icon: String {
        switch self {
        case .feed: return "house.fill"
        case .discover: return "safari"
        case .addRound: return "plus"
        case .activity: return "bell.fill"
        case .profile: return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .feed: return "Feed"
        case .discover: return "Discover"
        case .addRound: return "Round"
        case .activity: return "Activity"
        case .profile: return "Profile"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedTab: Tab = .feed
    @State private var showAddRound = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Screen content
            Group {
                switch selectedTab {
                case .feed:
                    FeedView()
                case .discover:
                    CourseSearchView()
                case .addRound:
                    Color.clear // Handled by sheet
                case .activity:
                    ActivityView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, onAddTapped: {
                showAddRound = true
            })
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddRound) {
            AddRoundView()
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var onAddTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                if tab == .addRound {
                    // Center floating button
                    Button(action: onAddTapped) {
                        ZStack {
                            Circle()
                                .fill(GolfrColors.heroGradient)
                                .frame(width: 56, height: 56)
                                .shadow(color: GolfrColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)

                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .offset(y: -16)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? GolfrColors.primary : GolfrColors.textSecondary.opacity(0.6))
                                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)

                            Text(tab.label)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(selectedTab == tab ? GolfrColors.primary : GolfrColors.textSecondary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 20)
        .background(
            TabBarBackground()
        )
    }
}

// MARK: - Tab Bar Background

struct TabBarBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: -4)
            .padding(.horizontal, 12)
    }
}
