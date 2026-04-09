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
        case .discover: return "magnifyingglass"
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
        VStack(spacing: 0) {
            // Top separator line
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    if tab == .addRound {
                        Button(action: onAddTapped) {
                            ZStack {
                                Circle()
                                    .fill(GolfrColors.heroGradient)
                                    .frame(width: 48, height: 48)
                                    .shadow(color: GolfrColors.primary.opacity(0.3), radius: 8, x: 0, y: 3)

                                Image(systemName: "plus")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                    } else {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? GolfrColors.primary : GolfrColors.textSecondary.opacity(0.45))
                                .scaleEffect(selectedTab == tab ? 1.15 : 1.0)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .contentShape(Rectangle())
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .background(
            TabBarBackground()
        )
    }
}

// MARK: - Tab Bar Background

struct TabBarBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -2)
            .ignoresSafeArea(.all, edges: .bottom)
    }
}
