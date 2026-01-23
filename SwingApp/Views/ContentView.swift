import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "house")
                }
            
            CourseSearchView()
                .tabItem {
                    Label("Courses", systemImage: "magnifyingglass")
                }
            
            ProfileView()
                .environmentObject(appViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .accentColor(.green) // Golf theme
    }
}
