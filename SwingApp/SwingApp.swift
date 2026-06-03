import SwiftUI
import GooglePlacesSwift
import GoogleMaps

@main
struct SwingApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    init() {
        PlacesClient.provideAPIKey(Secrets.googleMapsAPIKey)
        GMSServices.provideAPIKey(Secrets.googleMapsAPIKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
    }
}
