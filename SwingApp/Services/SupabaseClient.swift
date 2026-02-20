import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: Secrets.supabaseURL,
    supabaseKey: Secrets.supabaseAnonKey,
    options: SupabaseClientOptions(
        db: .init(schema: "public"),
        auth: .init(flowType: .pkce),
        global: .init(
            headers: ["x-app-name": "Golfr"]
        )
    )
)
