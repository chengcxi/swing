import Foundation
import Supabase

struct SupabaseConfig { // Move to secrets before prod
    static let url = URL(string: "https://qiunnjybpsvfohbfvxco.supabase.co")!
    static let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFpdW5uanlicHN2Zm9oYmZ2eGNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3MDY4MDEsImV4cCI6MjA4NTI4MjgwMX0.VhQdGntcq61C5KvNFhg-7klpCy3OpN4AoO6myQcMa4g"
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.key
)
