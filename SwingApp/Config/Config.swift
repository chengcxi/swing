import Foundation

enum Config {
    // MARK: - Supabase
    static let supabaseURL = Secrets.supabaseURL.absoluteString
    static let supabaseAnonKey = Secrets.supabaseAnonKey
    
    // MARK: - Google Maps
    static let googleMapsAPIKey = "GOOGLE_MAPS_API_KEY"
    
    // MARK: - App Settings
    static let defaultSearchRadiusKm: Double = 50.0
    static let feedPageSize: Int = 20
    static let maxPhotoUploads: Int = 5
}
