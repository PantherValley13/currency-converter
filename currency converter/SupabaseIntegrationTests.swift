import Foundation
#if canImport(Testing)
import Testing
#endif
#if canImport(Supabase)
import Supabase
#endif

#if canImport(Testing)
@Suite("Supabase integration tests")
struct SupabaseIntegrationTests {

    // This test is designed to run in local/dev environments where Supabase is configured.
    // It skips automatically when the SDK isn't present or configuration is missing.
    @Test(arguments: [true])
    func canFetchActiveProviderProfiles(_ run: Bool) async throws {
        #if !canImport(Supabase)
        throw XCTSkip("Supabase SDK not available; skipping integration test.")
        #else
        // Check for configuration presence (either Info.plist or DEBUG env)
        let bundleURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let bundleKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        let envURL = env["SUPABASE_URL"]
        let envKey = env["SUPABASE_ANON_KEY"]
        let legacyPID = env["SupaBase_ID"]
        let legacyKey = env["SupaBase_API_Key"]
        #else
        let envURL: String? = nil
        let envKey: String? = nil
        let legacyPID: String? = nil
        let legacyKey: String? = nil
        #endif

        let hasPlist = (bundleURL?.isEmpty == false && bundleKey?.isEmpty == false)
        let hasNewEnv = (envURL?.isEmpty == false && envKey?.isEmpty == false)
        let hasLegacyEnv = (legacyPID?.isEmpty == false && legacyKey?.isEmpty == false)

        if !(hasPlist || hasNewEnv || hasLegacyEnv) {
            throw XCTSkip("Supabase not configured; skipping integration test.")
        }

        // Exercise the manager
        let manager = SupabaseManager.shared
        do {
            let profiles = try await manager.fetchProviderProfiles()
            // We don't assert on specific contents, just that the call succeeded
            #expect(profiles.count >= 0)
        } catch {
            // If RLS or schema is not set up, this could fail; surface as a test failure
            Issue.record("Failed to fetch provider profiles: \(error)")
        }
        #endif
    }
}
#endif
