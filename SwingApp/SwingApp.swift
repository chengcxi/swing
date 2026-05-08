import SwiftUI
import GooglePlacesSwift
import GoogleMaps

@main
struct SwingApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    init() {
        PlacesClient.shared.provideAPIKey(Secrets.googleMapsAPIKey)
        GMSServices.provideAPIKey(Secrets.googleMapsAPIKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
    }
}
