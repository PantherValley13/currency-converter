import Foundation
import os
#if canImport(Supabase)
import Supabase
#endif

#if !canImport(Supabase) && !DEBUG
#error("Supabase SDK must be included for Release builds.")
#endif

private enum AppConfig {
    static var supabaseURL: URL? {
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           let url = URL(string: urlString) {
            return url
        }
        return nil
    }
    static var supabaseAnonKey: String? {
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !key.isEmpty {
            return key
        }
        return nil
    }
}

/// Centralized Supabase client.
///
/// Expects the following Xcode Scheme environment variables to be set:
/// - `SupaBase_API_Key`: your Supabase anon/public API key
/// - `SupaBase_ID`: your Supabase project id (the subdomain before `.supabase.co`)
///
/// Example URL built: `https://<SupaBase_ID>.supabase.co`
final class SupabaseManager {
    static let shared = SupabaseManager()

    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "App", category: "Supabase")

    private func maskedKey(_ key: String?) -> String {
        guard let key, !key.isEmpty else { return "empty" }
        let visibleCount = min(4, key.count)
        let prefix = key.prefix(visibleCount)
        return "\(prefix)••• (len=\(key.count))"
    }

    /// Base URL for the Supabase project, e.g. https://xyzcompany.supabase.co
    let baseURL: URL

    #if canImport(Supabase)
    /// Supabase client from the official `supabase-swift` package.
    let client: SupabaseClient
    #else
    /// Fallback client placeholder when Supabase SDK isn't available.
    let client: Any? = nil
    #endif

    private init() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        let envProjectID = env["SupaBase_ID"]
        let envAnonKey = env["SupaBase_API_Key"]
        #else
        let envProjectID: String? = nil
        let envAnonKey: String? = nil
        #endif

        let urlFromPlist = AppConfig.supabaseURL
        let keyFromPlist = AppConfig.supabaseAnonKey

        let finalURL: URL
        let finalKey: String

        if let url = urlFromPlist, let key = keyFromPlist {
            finalURL = url
            finalKey = key
        } else if let pid = envProjectID, let key = envAnonKey, !pid.isEmpty, !key.isEmpty {
            finalURL = URL(string: "https://\(pid).supabase.co") ?? URL(string: "https://invalid.supabase.co")!
            finalKey = key
        } else {
            #if DEBUG
            finalURL = URL(string: "https://invalid.supabase.co")!
            finalKey = ""
            #else
            preconditionFailure("Missing Supabase configuration. Provide SUPABASE_URL and SUPABASE_ANON_KEY in Info.plist.")
            #endif
        }

        self.baseURL = finalURL
        #if canImport(Supabase)
        self.client = SupabaseClient(supabaseURL: finalURL, supabaseKey: finalKey)
        #endif
    }

    /// Prints a short sanity check so you can verify environment variables are being read at runtime.
    func logEnvironmentCheck() {
        let plistURL = AppConfig.supabaseURL?.absoluteString ?? "(missing)"
        let plistKey = AppConfig.supabaseAnonKey
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        let envPID = env["SupaBase_ID"]
        let envKey = env["SupaBase_API_Key"]
        #else
        let envPID: String? = nil
        let envKey: String? = nil
        #endif
        SupabaseManager.log.info("[Supabase] Config check — URL(plist): \(plistURL), Key(plist): \(self.maskedKey(plistKey)), Env PID: \(envPID ?? "(n/a)"), Env Key: \(self.maskedKey(envKey)), Effective URL: \(self.baseURL.absoluteString)")
    }
    
    func testConnection() async {
        #if !canImport(Supabase)
        SupabaseManager.log.info("[Supabase] Supabase SDK not available in this build. Install the 'supabase-swift' package to enable backend features.")
        return
        #else
        do {
            let profiles = try await fetchProviderProfiles()
            SupabaseManager.log.info("[Supabase] Connection successful! Found \(profiles.count) provider profiles")
            for profile in profiles {
                SupabaseManager.log.info("[Supabase] - \(profile.name): \(profile.key)")
            }
        } catch {
            SupabaseManager.log.error("[Supabase] Connection failed: \(error.localizedDescription)")
        }
        #endif
    }
}

// MARK: - Data Models
struct User: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let preferences: [String: AnyCodable]
    let lastActive: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case preferences
        case lastActive = "last_active"
    }
}

struct CurrencyRate: Codable, Identifiable {
    let id: UUID
    let baseCurrency: String
    let targetCurrency: String
    let rate: Decimal
    let provider: String
    let createdAt: Date
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case baseCurrency = "base_currency"
        case targetCurrency = "target_currency"
        case rate
        case provider
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

struct WatchlistItem: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let currencyCode: String
    let position: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currencyCode = "currency_code"
        case position
        case createdAt = "created_at"
    }
}

struct SupabaseAlertRule: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let baseCurrency: String
    let targetCurrency: String
    let threshold: Decimal
    let direction: String // "above" or "below"
    let isActive: Bool
    let createdAt: Date
    let triggeredAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case baseCurrency = "base_currency"
        case targetCurrency = "target_currency"
        case threshold
        case direction
        case isActive = "is_active"
        case createdAt = "created_at"
        case triggeredAt = "triggered_at"
    }
}

struct SupabaseQuickPair: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let baseCurrency: String
    let targetCurrency: String
    let position: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case baseCurrency = "base_currency"
        case targetCurrency = "target_currency"
        case position
        case createdAt = "created_at"
    }
}

struct AmountPreset: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let amount: Decimal
    let position: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case position
        case createdAt = "created_at"
    }
}

struct ConversionHistory: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let baseCurrency: String
    let targetCurrency: String
    let amount: Decimal
    let rate: Decimal
    let result: Decimal
    let provider: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case baseCurrency = "base_currency"
        case targetCurrency = "target_currency"
        case amount
        case rate
        case result
        case provider
        case createdAt = "created_at"
    }
}

struct SupabaseProviderProfile: Codable, Identifiable {
    let id: UUID
    let key: String
    let name: String
    let spreadPercent: Decimal
    let fixedFee: Decimal
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case key
        case name
        case spreadPercent = "spread_percent"
        case fixedFee = "fixed_fee"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// Helper for JSON encoding/decoding
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

enum SupabaseError: Error {
    case unauthenticated
    case invalidConfiguration
}

// MARK: - SupabaseManager Extensions
#if canImport(Supabase)
extension SupabaseManager {
    
    // MARK: - User Management
    func getCurrentUser() async throws -> User? {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        return try await client.database
            .from("users")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value
    }
    
    func updateUserPreferences(_ preferences: [String: Any]) async throws {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        let anyCodablePrefs = preferences.mapValues { AnyCodable($0) }
        try await client.database
            .from("users")
            .update(["preferences": anyCodablePrefs, "updated_at": Date()])
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }
    
    // MARK: - Watchlist Management
    func fetchWatchlist() async throws -> [WatchlistItem] {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        return try await client.database
            .from("watchlists")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .order("position")
            .execute()
            .value
    }
    
    func addToWatchlist(currencyCode: String, position: Int = 0) async throws {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        let item = WatchlistItem(
            id: UUID(),
            userId: session.user.id,
            currencyCode: currencyCode,
            position: position,
            createdAt: Date()
        )
        try await client.database
            .from("watchlists")
            .insert(item)
            .execute()
    }
    
    func removeFromWatchlist(currencyCode: String) async throws {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        try await client.database
            .from("watchlists")
            .delete()
            .eq("user_id", value: session.user.id.uuidString)
            .eq("currency_code", value: currencyCode)
            .execute()
    }
    
    // MARK: - Alert Rules Management
    func fetchAlertRules() async throws -> [SupabaseAlertRule] {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        return try await client.database
            .from("alert_rules")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func addAlertRule(baseCurrency: String, targetCurrency: String, threshold: Decimal, direction: String) async throws {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        let rule = SupabaseAlertRule(
            id: UUID(),
            userId: session.user.id,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            threshold: threshold,
            direction: direction,
            isActive: true,
            createdAt: Date(),
            triggeredAt: nil
        )
        try await client.database
            .from("alert_rules")
            .insert(rule)
            .execute()
    }
    
    func deleteAlertRule(id: UUID) async throws {
        try await client.database
            .from("alert_rules")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Quick Pairs Management
    func fetchQuickPairs() async throws -> [SupabaseQuickPair] {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        return try await client.database
            .from("quick_pairs")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .order("position")
            .execute()
            .value
    }
    
    func addQuickPair(baseCurrency: String, targetCurrency: String, position: Int = 0) async throws {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        let pair = SupabaseQuickPair(
            id: UUID(),
            userId: session.user.id,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            position: position,
            createdAt: Date()
        )
        try await client.database
            .from("quick_pairs")
            .insert(pair)
            .execute()
    }
    
    func deleteQuickPair(id: UUID) async throws {
        try await client.database
            .from("quick_pairs")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Amount Presets Management
    func fetchAmountPresets() async throws -> [AmountPreset] {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        return try await client.database
            .from("amount_presets")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .order("position")
            .execute()
            .value
    }
    
    func addAmountPreset(amount: Decimal, position: Int = 0) async throws {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        let preset = AmountPreset(
            id: UUID(),
            userId: session.user.id,
            amount: amount,
            position: position,
            createdAt: Date()
        )
        try await client.database
            .from("amount_presets")
            .insert(preset)
            .execute()
    }
    
    func deleteAmountPreset(id: UUID) async throws {
        try await client.database
            .from("amount_presets")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Conversion History
    func logConversion(baseCurrency: String, targetCurrency: String, amount: Decimal, rate: Decimal, result: Decimal, provider: String = "interbank") async throws {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        let conversion = ConversionHistory(
            id: UUID(),
            userId: session.user.id,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            amount: amount,
            rate: rate,
            result: result,
            provider: provider,
            createdAt: Date()
        )
        try await client.database
            .from("conversion_history")
            .insert(conversion)
            .execute()
    }
    
    func fetchConversionHistory(limit: Int = 50) async throws -> [ConversionHistory] {
        guard let session = try? await client.auth.session else { throw SupabaseError.unauthenticated }
        return try await client.database
            .from("conversion_history")
            .select()
            .eq("user_id", value: session.user.id.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
    
    // MARK: - Provider Profiles
    func fetchProviderProfiles() async throws -> [SupabaseProviderProfile] {
        return try await client.database
            .from("provider_profiles")
            .select()
            .eq("is_active", value: true)
            .execute()
            .value
    }
    
    // MARK: - Currency Rates
    func fetchCurrencyRates(baseCurrency: String) async throws -> [CurrencyRate] {
        return try await client.database
            .from("currency_rates")
            .select()
            .eq("base_currency", value: baseCurrency)
            .gt("expires_at", value: Date())
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func cacheCurrencyRates(_ rates: [String: Decimal], baseCurrency: String, provider: String = "interbank") async throws {
        let now = Date()
        let expiresAt = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        
        let rateObjects = rates.map { (targetCurrency, rate) in
            CurrencyRate(
                id: UUID(),
                baseCurrency: baseCurrency,
                targetCurrency: targetCurrency,
                rate: rate,
                provider: provider,
                createdAt: now,
                expiresAt: expiresAt
            )
        }
        
        try await client.database
            .from("currency_rates")
            .insert(rateObjects)
            .execute()
    }
}

// MARK: - ContentView Integration Helpers
// These types match the ones in ContentView.swift
struct CurrencyAlertRule: Codable, Identifiable, Equatable {
    enum Direction: String, Codable, CaseIterable { case above, below }
    let id: UUID
    var base: String
    var target: String
    var threshold: Double
    var direction: Direction
}

struct CurrencyQuickPair: Codable, Hashable, Identifiable {
    let id: UUID
    var base: String
    var target: String

    init(id: UUID = UUID(), base: String, target: String) {
        self.id = id
        self.base = base
        self.target = target
    }
}

struct FXProviderProfile: Codable, Identifiable, Equatable {
    var id: String { key }
    let key: String
    let name: String
    let spreadPercent: Double
    let fixedFee: Double
}

extension SupabaseManager {
    
    /// Sync local alert rules with Supabase
    func syncAlertRules(_ localRules: [CurrencyAlertRule]) async throws {
        // Convert local rules to Supabase format and sync
        for rule in localRules {
            do {
                try await addAlertRule(
                    baseCurrency: rule.base,
                    targetCurrency: rule.target,
                    threshold: Decimal(rule.threshold),
                    direction: rule.direction.rawValue
                )
            } catch {
                SupabaseManager.log.error("[Supabase] Failed to sync alert rule: \(error.localizedDescription)")
            }
        }
    }
    
    /// Load alert rules from Supabase and convert to local format
    func loadAlertRulesForContentView() async throws -> [CurrencyAlertRule] {
        let supabaseRules = try await fetchAlertRules()
        return supabaseRules.map { rule in
            CurrencyAlertRule(
                id: rule.id,
                base: rule.baseCurrency,
                target: rule.targetCurrency,
                threshold: NSDecimalNumber(decimal: rule.threshold).doubleValue,
                direction: CurrencyAlertRule.Direction(rawValue: rule.direction) ?? .below
            )
        }
    }
    
    /// Sync local quick pairs with Supabase
    func syncQuickPairs(_ localPairs: [CurrencyQuickPair]) async throws {
        // Clear existing pairs first
        let existingPairs = try await fetchQuickPairs()
        for pair in existingPairs {
            try await deleteQuickPair(id: pair.id)
        }
        
        // Add new pairs
        for (index, pair) in localPairs.enumerated() {
            try await addQuickPair(
                baseCurrency: pair.base,
                targetCurrency: pair.target,
                position: index
            )
        }
    }
    
    /// Load quick pairs from Supabase and convert to local format
    func loadQuickPairsForContentView() async throws -> [CurrencyQuickPair] {
        let supabasePairs = try await fetchQuickPairs()
        return supabasePairs.map { pair in
            CurrencyQuickPair(
                base: pair.baseCurrency,
                target: pair.targetCurrency
            )
        }
    }
    
    /// Load provider profiles from Supabase and convert to local format
    func loadProviderProfilesForContentView() async throws -> [FXProviderProfile] {
        let supabaseProfiles = try await fetchProviderProfiles()
        return supabaseProfiles.map { profile in
            FXProviderProfile(
                key: profile.key,
                name: profile.name,
                spreadPercent: NSDecimalNumber(decimal: profile.spreadPercent).doubleValue,
                fixedFee: NSDecimalNumber(decimal: profile.fixedFee).doubleValue
            )
        }
    }
    
    /// Log a conversion to Supabase
    func logConversionForContentView(
        baseCurrency: String,
        targetCurrency: String,
        amount: Double,
        rate: Double,
        result: Double,
        provider: String = "interbank"
    ) async {
        do {
            try await logConversion(
                baseCurrency: baseCurrency,
                targetCurrency: targetCurrency,
                amount: Decimal(amount),
                rate: Decimal(rate),
                result: Decimal(result),
                provider: provider
            )
        } catch {
            SupabaseManager.log.error("[Supabase] Failed to log conversion: \(error.localizedDescription)")
        }
    }
}
#endif

#if !canImport(Supabase)
extension SupabaseManager {
    // MARK: - User Management (stubs)
    func getCurrentUser() async throws -> User? { nil }
    func updateUserPreferences(_ preferences: [String: Any]) async throws {}

    // MARK: - Watchlist Management (stubs)
    func fetchWatchlist() async throws -> [WatchlistItem] { [] }
    func addToWatchlist(currencyCode: String, position: Int = 0) async throws {}
    func removeFromWatchlist(currencyCode: String) async throws {}

    // MARK: - Alert Rules Management (stubs)
    func fetchAlertRules() async throws -> [SupabaseAlertRule] { [] }
    func addAlertRule(baseCurrency: String, targetCurrency: String, threshold: Decimal, direction: String) async throws {}
    func deleteAlertRule(id: UUID) async throws {}

    // MARK: - Quick Pairs Management (stubs)
    func fetchQuickPairs() async throws -> [SupabaseQuickPair] { [] }
    func addQuickPair(baseCurrency: String, targetCurrency: String, position: Int = 0) async throws {}
    func deleteQuickPair(id: UUID) async throws {}

    // MARK: - Amount Presets Management (stubs)
    func fetchAmountPresets() async throws -> [AmountPreset] { [] }
    func addAmountPreset(amount: Decimal, position: Int = 0) async throws {}
    func deleteAmountPreset(id: UUID) async throws {}

    // MARK: - Conversion History (stubs)
    func logConversion(baseCurrency: String, targetCurrency: String, amount: Decimal, rate: Decimal, result: Decimal, provider: String = "interbank") async throws {}
    func fetchConversionHistory(limit: Int = 50) async throws -> [ConversionHistory] { [] }

    // MARK: - Provider Profiles (stubs)
    func fetchProviderProfiles() async throws -> [SupabaseProviderProfile] { [] }

    // MARK: - Currency Rates (stubs)
    func fetchCurrencyRates(baseCurrency: String) async throws -> [CurrencyRate] { [] }
    func cacheCurrencyRates(_ rates: [String: Decimal], baseCurrency: String, provider: String = "interbank") async throws {}
}
#endif

