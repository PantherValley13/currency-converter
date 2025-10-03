import XCTest
import Foundation
@testable import currency_converter

/// Tests for data persistence and caching mechanisms
final class DataPersistenceTests: XCTestCase {
    
    var userDefaults: UserDefaults!
    var cacheManager: MockCacheManager!
    
    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: "TestUserDefaults")!
        userDefaults.removePersistentDomain(forName: "TestUserDefaults")
        cacheManager = MockCacheManager()
    }
    
    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: "TestUserDefaults")
        userDefaults = nil
        cacheManager = nil
    }
    
    // MARK: - User Preferences Tests
    
    func testUserPreferencesPersistence() throws {
        // Given
        let preferences = [
            "theme": AnyCodable("dark"),
            "autoRefresh": AnyCodable(true),
            "refreshInterval": AnyCodable(60),
            "favorites": AnyCodable(["USD", "EUR", "GBP"])
        ]
        
        // When
        let data = try JSONEncoder().encode(preferences)
        userDefaults.set(data, forKey: "userPreferences")
        
        let retrievedData = userDefaults.data(forKey: "userPreferences")!
        let retrievedPreferences = try JSONDecoder().decode([String: AnyCodable].self, from: retrievedData)
        
        // Then
        XCTAssertEqual(retrievedPreferences.count, 4)
        XCTAssertEqual(retrievedPreferences["theme"]?.value as? String, "dark")
        XCTAssertEqual(retrievedPreferences["autoRefresh"]?.value as? Bool, true)
        XCTAssertEqual(retrievedPreferences["refreshInterval"]?.value as? Int, 60)
    }
    
    func testUserPreferencesUpdate() throws {
        // Given
        var preferences = [
            "theme": AnyCodable("light"),
            "autoRefresh": AnyCodable(false)
        ]
        
        // When
        let data = try JSONEncoder().encode(preferences)
        userDefaults.set(data, forKey: "userPreferences")
        
        // Update preferences
        preferences["theme"] = AnyCodable("dark")
        preferences["refreshInterval"] = AnyCodable(120)
        
        let updatedData = try JSONEncoder().encode(preferences)
        userDefaults.set(updatedData, forKey: "userPreferences")
        
        let retrievedData = userDefaults.data(forKey: "userPreferences")!
        let retrievedPreferences = try JSONDecoder().decode([String: AnyCodable].self, from: retrievedData)
        
        // Then
        XCTAssertEqual(retrievedPreferences["theme"]?.value as? String, "dark")
        XCTAssertEqual(retrievedPreferences["refreshInterval"]?.value as? Int, 120)
    }
    
    // MARK: - Alert Rules Persistence Tests
    
    func testAlertRulesPersistence() throws {
        // Given
        let alertRules = [
            CurrencyAlertRule(
                id: UUID(),
                base: "USD",
                target: "EUR",
                threshold: 0.95,
                direction: .above
            ),
            CurrencyAlertRule(
                id: UUID(),
                base: "USD",
                target: "GBP",
                threshold: 0.75,
                direction: .below
            )
        ]
        
        // When
        let data = try JSONEncoder().encode(alertRules)
        userDefaults.set(data, forKey: "alertRules")
        
        let retrievedData = userDefaults.data(forKey: "alertRules")!
        let retrievedRules = try JSONDecoder().decode([CurrencyAlertRule].self, from: retrievedData)
        
        // Then
        XCTAssertEqual(retrievedRules.count, 2)
        XCTAssertEqual(retrievedRules[0].base, "USD")
        XCTAssertEqual(retrievedRules[0].target, "EUR")
        XCTAssertEqual(retrievedRules[0].threshold, 0.95)
        XCTAssertEqual(retrievedRules[0].direction, .above)
    }
    
    func testAlertRulesUpdate() throws {
        // Given
        var alertRules = [
            CurrencyAlertRule(
                id: UUID(),
                base: "USD",
                target: "EUR",
                threshold: 0.95,
                direction: .above
            )
        ]
        
        // When
        let data = try JSONEncoder().encode(alertRules)
        userDefaults.set(data, forKey: "alertRules")
        
        // Update rules
        alertRules[0].threshold = 0.90
        alertRules.append(CurrencyAlertRule(
            id: UUID(),
            base: "EUR",
            target: "USD",
            threshold: 1.10,
            direction: .above
        ))
        
        let updatedData = try JSONEncoder().encode(alertRules)
        userDefaults.set(updatedData, forKey: "alertRules")
        
        let retrievedData = userDefaults.data(forKey: "alertRules")!
        let retrievedRules = try JSONDecoder().decode([CurrencyAlertRule].self, from: retrievedData)
        
        // Then
        XCTAssertEqual(retrievedRules.count, 2)
        XCTAssertEqual(retrievedRules[0].threshold, 0.90)
        XCTAssertEqual(retrievedRules[1].base, "EUR")
    }
    
    // MARK: - Quick Pairs Persistence Tests
    
    func testQuickPairsPersistence() throws {
        // Given
        let quickPairs = [
            CurrencyQuickPair(base: "USD", target: "EUR"),
            CurrencyQuickPair(base: "USD", target: "JPY"),
            CurrencyQuickPair(base: "EUR", target: "GBP")
        ]
        
        // When
        let data = try JSONEncoder().encode(quickPairs)
        userDefaults.set(data, forKey: "quickPairs")
        
        let retrievedData = userDefaults.data(forKey: "quickPairs")!
        let retrievedPairs = try JSONDecoder().decode([CurrencyQuickPair].self, from: retrievedData)
        
        // Then
        XCTAssertEqual(retrievedPairs.count, 3)
        XCTAssertEqual(retrievedPairs[0].base, "USD")
        XCTAssertEqual(retrievedPairs[0].target, "EUR")
    }
    
    func testQuickPairsOrderPersistence() throws {
        // Given
        let quickPairs = [
            CurrencyQuickPair(base: "USD", target: "EUR"),
            CurrencyQuickPair(base: "USD", target: "JPY"),
            CurrencyQuickPair(base: "EUR", target: "GBP")
        ]
        
        // When
        let data = try JSONEncoder().encode(quickPairs)
        userDefaults.set(data, forKey: "quickPairs")
        
        let retrievedData = userDefaults.data(forKey: "quickPairs")!
        let retrievedPairs = try JSONDecoder().decode([CurrencyQuickPair].self, from: retrievedData)
        
        // Then
        XCTAssertEqual(retrievedPairs[0].base, "USD")
        XCTAssertEqual(retrievedPairs[1].base, "USD")
        XCTAssertEqual(retrievedPairs[2].base, "EUR")
    }
    
    // MARK: - Cache Management Tests
    
    func testRatesCacheStorage() throws {
        // Given
        let rates = [
            "USD": 1.0,
            "EUR": 0.92,
            "GBP": 0.79,
            "JPY": 147.0
        ]
        let baseCurrency = "USD"
        let timestamp = Date()
        
        // When
        try cacheManager.storeRates(rates, baseCurrency: baseCurrency, timestamp: timestamp)
        
        // Then
        XCTAssertTrue(cacheManager.hasCachedRates(for: baseCurrency))
        let cachedRates = cacheManager.getCachedRates(for: baseCurrency)
        XCTAssertEqual(cachedRates?.rates["EUR"], 0.92)
        XCTAssertEqual(cachedRates?.baseCurrency, baseCurrency)
    }
    
    func testRatesCacheExpiration() throws {
        // Given
        let rates = ["USD": 1.0, "EUR": 0.92]
        let baseCurrency = "USD"
        let expiredTimestamp = Date().addingTimeInterval(-7200) // 2 hours ago
        
        // When
        try cacheManager.storeRates(rates, baseCurrency: baseCurrency, timestamp: expiredTimestamp)
        
        // Then
        XCTAssertFalse(cacheManager.hasCachedRates(for: baseCurrency))
        XCTAssertNil(cacheManager.getCachedRates(for: baseCurrency))
    }
    
    func testRatesCacheUpdate() throws {
        // Given
        let initialRates = ["USD": 1.0, "EUR": 0.92]
        let updatedRates = ["USD": 1.0, "EUR": 0.93, "GBP": 0.79]
        let baseCurrency = "USD"
        let timestamp = Date()
        
        // When
        try cacheManager.storeRates(initialRates, baseCurrency: baseCurrency, timestamp: timestamp)
        try cacheManager.storeRates(updatedRates, baseCurrency: baseCurrency, timestamp: timestamp)
        
        // Then
        let cachedRates = cacheManager.getCachedRates(for: baseCurrency)
        XCTAssertEqual(cachedRates?.rates["EUR"], 0.93)
        XCTAssertEqual(cachedRates?.rates["GBP"], 0.79)
        XCTAssertEqual(cachedRates?.rates.count, 3)
    }
    
    func testCacheCleanup() throws {
        // Given
        let rates1 = ["USD": 1.0, "EUR": 0.92]
        let rates2 = ["USD": 1.0, "GBP": 0.79]
        let expiredTimestamp = Date().addingTimeInterval(-7200)
        let currentTimestamp = Date()
        
        // When
        try cacheManager.storeRates(rates1, baseCurrency: "USD", timestamp: expiredTimestamp)
        try cacheManager.storeRates(rates2, baseCurrency: "EUR", timestamp: currentTimestamp)
        
        cacheManager.cleanupExpiredRates()
        
        // Then
        XCTAssertFalse(cacheManager.hasCachedRates(for: "USD"))
        XCTAssertTrue(cacheManager.hasCachedRates(for: "EUR"))
    }
    
    // MARK: - Offline Pack Tests
    
    func testOfflinePackCreation() throws {
        // Given
        let rates = [
            "USD": 1.0,
            "EUR": 0.92,
            "GBP": 0.79,
            "JPY": 147.0
        ]
        let baseCurrency = "USD"
        let timestamp = Date()
        
        // When
        let offlinePack = try cacheManager.createOfflinePack(
            rates: rates,
            baseCurrency: baseCurrency,
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(offlinePack.baseCurrency, baseCurrency)
        XCTAssertEqual(offlinePack.rates["EUR"], 0.92)
        XCTAssertEqual(offlinePack.timestamp, timestamp)
    }
    
    func testOfflinePackStorage() throws {
        // Given
        let rates = ["USD": 1.0, "EUR": 0.92]
        let baseCurrency = "USD"
        let timestamp = Date()
        
        // When
        let offlinePack = try cacheManager.createOfflinePack(
            rates: rates,
            baseCurrency: baseCurrency,
            timestamp: timestamp
        )
        try cacheManager.storeOfflinePack(offlinePack)
        
        // Then
        let storedPack = cacheManager.getStoredOfflinePack()
        XCTAssertNotNil(storedPack)
        XCTAssertEqual(storedPack?.baseCurrency, baseCurrency)
        XCTAssertEqual(storedPack?.rates["EUR"], 0.92)
    }
    
    func testOfflinePackLoading() throws {
        // Given
        let rates = ["USD": 1.0, "EUR": 0.92]
        let baseCurrency = "USD"
        let timestamp = Date()
        
        // When
        let offlinePack = try cacheManager.createOfflinePack(
            rates: rates,
            baseCurrency: baseCurrency,
            timestamp: timestamp
        )
        try cacheManager.storeOfflinePack(offlinePack)
        
        let loadedRates = cacheManager.loadOfflineRates()
        
        // Then
        XCTAssertNotNil(loadedRates)
        XCTAssertEqual(loadedRates?["EUR"], 0.92)
    }
    
    // MARK: - Data Migration Tests
    
    func testLegacyDataMigration() throws {
        // Given
        let legacyData = [
            "base": "USD",
            "rates": [
                "EUR": 0.92,
                "GBP": 0.79
            ],
            "updated": Date().timeIntervalSince1970
        ] as [String: Any]
        
        let data = try JSONSerialization.data(withJSONObject: legacyData, options: [])
        userDefaults.set(data, forKey: "cachedRatesJSON")
        
        // When
        let migratedRates = try cacheManager.migrateLegacyData()
        
        // Then
        XCTAssertNotNil(migratedRates)
        XCTAssertEqual(migratedRates?.rates["EUR"], 0.92)
        XCTAssertEqual(migratedRates?.baseCurrency, "USD")
    }
    
    func testDataValidation() throws {
        // Given
        let invalidData = "invalid json".data(using: .utf8)!
        userDefaults.set(invalidData, forKey: "alertRules")
        
        // When & Then
        XCTAssertThrowsError(try cacheManager.validateStoredData(), "Invalid data should throw error")
    }
    
    // MARK: - Performance Tests
    
    func testLargeDataSetPersistence() throws {
        // Given
        let largeRates = (0..<1000).reduce(into: [String: Double]()) { rates, index in
            rates["CURRENCY\(index)"] = Double.random(in: 0.1...100.0)
        }
        let baseCurrency = "USD"
        let timestamp = Date()
        
        // When & Then
        measure {
            try? cacheManager.storeRates(largeRates, baseCurrency: baseCurrency, timestamp: timestamp)
        }
    }
    
    func testCacheRetrievalPerformance() throws {
        // Given
        let rates = ["USD": 1.0, "EUR": 0.92, "GBP": 0.79]
        let baseCurrency = "USD"
        let timestamp = Date()
        
        try cacheManager.storeRates(rates, baseCurrency: baseCurrency, timestamp: timestamp)
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = cacheManager.getCachedRates(for: baseCurrency)
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageWithLargeCache() throws {
        // Given
        let largeRates = (0..<10000).reduce(into: [String: Double]()) { rates, index in
            rates["CURRENCY\(index)"] = Double.random(in: 0.1...100.0)
        }
        let baseCurrency = "USD"
        let timestamp = Date()
        
        // When
        let startMemory = getMemoryUsage()
        try cacheManager.storeRates(largeRates, baseCurrency: baseCurrency, timestamp: timestamp)
        let endMemory = getMemoryUsage()
        
        // Then
        let memoryIncrease = endMemory - startMemory
        XCTAssertLessThan(memoryIncrease, 100_000_000, "Memory increase should be less than 100MB")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}

// MARK: - Mock Cache Manager

class MockCacheManager {
    private var cachedRates: [String: CachedRates] = [:]
    private var offlinePack: OfflinePack?
    private let cacheExpirationTime: TimeInterval = 3600 // 1 hour
    
    func storeRates(_ rates: [String: Double], baseCurrency: String, timestamp: Date) throws {
        let cachedRates = CachedRates(
            baseCurrency: baseCurrency,
            rates: rates,
            timestamp: timestamp
        )
        self.cachedRates[baseCurrency] = cachedRates
    }
    
    func getCachedRates(for baseCurrency: String) -> CachedRates? {
        guard let cached = cachedRates[baseCurrency] else { return nil }
        
        if Date().timeIntervalSince(cached.timestamp) > cacheExpirationTime {
            cachedRates.removeValue(forKey: baseCurrency)
            return nil
        }
        
        return cached
    }
    
    func hasCachedRates(for baseCurrency: String) -> Bool {
        return getCachedRates(for: baseCurrency) != nil
    }
    
    func cleanupExpiredRates() {
        let now = Date()
        cachedRates = cachedRates.filter { _, cached in
            now.timeIntervalSince(cached.timestamp) <= cacheExpirationTime
        }
    }
    
    func createOfflinePack(rates: [String: Double], baseCurrency: String, timestamp: Date) throws -> OfflinePack {
        return OfflinePack(
            baseCurrency: baseCurrency,
            rates: rates,
            timestamp: timestamp
        )
    }
    
    func storeOfflinePack(_ pack: OfflinePack) throws {
        offlinePack = pack
    }
    
    func getStoredOfflinePack() -> OfflinePack? {
        return offlinePack
    }
    
    func loadOfflineRates() -> [String: Double]? {
        return offlinePack?.rates
    }
    
    func migrateLegacyData() throws -> CachedRates? {
        // Mock implementation for legacy data migration
        return nil
    }
    
    func validateStoredData() throws {
        // Mock implementation for data validation
        if cachedRates.isEmpty && offlinePack == nil {
            throw NSError(domain: "MockCacheManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No valid data found"])
        }
    }
}

// MARK: - Data Models

struct CachedRates: Codable {
    let baseCurrency: String
    let rates: [String: Double]
    let timestamp: Date
}

struct OfflinePack: Codable {
    let baseCurrency: String
    let rates: [String: Double]
    let timestamp: Date
}
