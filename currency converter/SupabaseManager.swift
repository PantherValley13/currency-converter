import Foundation
import Supabase

/// Centralized Supabase client.
///
/// Expects the following Xcode Scheme environment variables to be set:
/// - `SupaBase_API_Key`: your Supabase anon/public API key
/// - `SupaBase_ID`: your Supabase project id (the subdomain before `.supabase.co`)
///
/// Example URL built: `https://<SupaBase_ID>.supabase.co`
final class SupabaseManager {
    static let shared = SupabaseManager()

    /// Base URL for the Supabase project, e.g. https://xyzcompany.supabase.co
    let baseURL: URL

    /// Supabase client from the official `supabase-swift` package.
    let client: SupabaseClient

    private init() {
        let env = ProcessInfo.processInfo.environment
        let projectID = env["SupaBase_ID"] ?? ""
        let anonKey = env["SupaBase_API_Key"] ?? ""

        // It's okay if these are empty in debug; we'll still create a URL to avoid hard-crashing.
        let constructedURL = URL(string: "https://\(projectID).supabase.co") ?? URL(string: "https://invalid.supabase.co")!
        self.baseURL = constructedURL
        self.client = SupabaseClient(supabaseURL: constructedURL, supabaseKey: anonKey)
    }

    /// Prints a short sanity check so you can verify environment variables are being read at runtime.
    func logEnvironmentCheck() {
        let env = ProcessInfo.processInfo.environment
        let pid = env["SupaBase_ID"] ?? "(missing)"
        let key = env["SupaBase_API_Key"] ?? "(missing)"
        let maskedKey: String
        if key.isEmpty || key == "(missing)" {
            maskedKey = "empty"
        } else {
            let visibleCount = min(4, key.count)
            let prefix = key.prefix(visibleCount)
            maskedKey = "\(prefix)••• (len=\(key.count))"
        }
        print("[Supabase] ProjectID=\(pid), Key=\(maskedKey), URL=\(baseURL.absoluteString)")
    }
}

// MARK: - Example data models (scaffold)
// Extend with your own tables when ready, e.g.:
// struct WatchlistRow: Codable, Identifiable {
//     let id: UUID
//     let user_id: UUID
//     let code: String
//     let position: Int
// }
//
// extension SupabaseManager {
//     func fetchWatchlist(for userID: UUID) async throws -> [WatchlistRow] {
//         try await client.database
//             .from("watchlist")
//             .select()
//             .eq("user_id", value: userID.uuidString)
//             .order("position")
//             .execute()
//             .value
//     }
//
//     func upsertWatchlist(_ rows: [WatchlistRow]) async throws {
//         _ = try await client.database
//             .from("watchlist")
//             .upsert(rows)
//             .execute()
//     }
// }
