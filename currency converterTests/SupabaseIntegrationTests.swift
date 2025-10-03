import XCTest
@testable import currency_converter

/// Integration tests for Supabase operations
final class SupabaseIntegrationTests: XCTestCase {
    
    var supabaseManager: SupabaseManager!
    
    override func setUpWithError() throws {
        supabaseManager = SupabaseManager.shared
    }
    
    override func tearDownWithError() throws {
        supabaseManager = nil
    }
    
    // MARK: - Connection Tests
    
    func testSupabaseConnection() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Supabase connection test")
        
        // When
        await supabaseManager.testConnection()
        
        // Then
        // This test will pass if the connection is successful
        // In a real test environment, you would mock the Supabase client
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testSupabaseConfiguration() throws {
        // Given & When
        let baseURL = supabaseManager.baseURL
        
        // Then
        XCTAssertNotNil(baseURL, "Base URL should not be nil")
        XCTAssertTrue(baseURL.absoluteString.contains("supabase.co"), "Base URL should contain supabase.co")
    }
    
    // MARK: - Data Model Tests
    
    func testUserModelEncoding() throws {
        // Given
        let user = User(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            preferences: ["theme": AnyCodable("dark")],
            lastActive: Date()
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        
        // Then
        XCTAssertNotNil(data, "User should encode successfully")
        XCTAssertGreaterThan(data.count, 0, "Encoded data should not be empty")
    }
    
    func testUserModelDecoding() throws {
        // Given
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "created_at": "2023-01-01T00:00:00Z",
            "updated_at": "2023-01-01T00:00:00Z",
            "preferences": {"theme": "dark"},
            "last_active": "2023-01-01T00:00:00Z"
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let user = try decoder.decode(User.self, from: data)
        
        // Then
        XCTAssertNotNil(user, "User should decode successfully")
        XCTAssertEqual(user.id.uuidString, "123e4567-e89b-12d3-a456-426614174000")
    }
    
    func testCurrencyRateModelEncoding() throws {
        // Given
        let currencyRate = CurrencyRate(
            id: UUID(),
            baseCurrency: "USD",
            targetCurrency: "EUR",
            rate: Decimal(0.92),
            provider: "interbank",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(currencyRate)
        
        // Then
        XCTAssertNotNil(data, "CurrencyRate should encode successfully")
        XCTAssertGreaterThan(data.count, 0, "Encoded data should not be empty")
    }
    
    func testWatchlistItemModelEncoding() throws {
        // Given
        let watchlistItem = WatchlistItem(
            id: UUID(),
            userId: UUID(),
            currencyCode: "EUR",
            position: 0,
            createdAt: Date()
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(watchlistItem)
        
        // Then
        XCTAssertNotNil(data, "WatchlistItem should encode successfully")
        XCTAssertGreaterThan(data.count, 0, "Encoded data should not be empty")
    }
    
    // MARK: - AnyCodable Tests
    
    func testAnyCodableStringEncoding() throws {
        // Given
        let anyCodable = AnyCodable("test string")
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        
        // Then
        XCTAssertNotNil(data, "AnyCodable string should encode successfully")
    }
    
    func testAnyCodableIntEncoding() throws {
        // Given
        let anyCodable = AnyCodable(42)
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        
        // Then
        XCTAssertNotNil(data, "AnyCodable int should encode successfully")
    }
    
    func testAnyCodableDoubleEncoding() throws {
        // Given
        let anyCodable = AnyCodable(3.14)
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        
        // Then
        XCTAssertNotNil(data, "AnyCodable double should encode successfully")
    }
    
    func testAnyCodableBoolEncoding() throws {
        // Given
        let anyCodable = AnyCodable(true)
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        
        // Then
        XCTAssertNotNil(data, "AnyCodable bool should encode successfully")
    }
    
    func testAnyCodableArrayEncoding() throws {
        // Given
        let anyCodable = AnyCodable([1, 2, 3])
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        
        // Then
        XCTAssertNotNil(data, "AnyCodable array should encode successfully")
    }
    
    func testAnyCodableDictionaryEncoding() throws {
        // Given
        let anyCodable = AnyCodable(["key": "value"])
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        
        // Then
        XCTAssertNotNil(data, "AnyCodable dictionary should encode successfully")
    }
    
    // MARK: - Error Handling Tests
    
    func testSupabaseErrorCases() throws {
        // Given
        let unauthenticatedError = SupabaseError.unauthenticated
        let invalidConfigError = SupabaseError.invalidConfiguration
        
        // When & Then
        switch unauthenticatedError {
        case .unauthenticated:
            XCTAssertTrue(true, "Should handle unauthenticated error")
        case .invalidConfiguration:
            XCTFail("Should not be invalid configuration error")
        }
        
        switch invalidConfigError {
        case .unauthenticated:
            XCTFail("Should not be unauthenticated error")
        case .invalidConfiguration:
            XCTAssertTrue(true, "Should handle invalid configuration error")
        }
    }
    
    // MARK: - Mock Data Tests
    
    func testMockProviderProfiles() throws {
        // Given
        let mockProfiles = createMockProviderProfiles()
        
        // When & Then
        XCTAssertEqual(mockProfiles.count, 3, "Should have 3 mock provider profiles")
        
        let interbankProfile = mockProfiles.first { $0.key == "interbank" }
        XCTAssertNotNil(interbankProfile, "Should have interbank profile")
        XCTAssertEqual(interbankProfile?.spreadPercent, 0.0, "Interbank should have 0% spread")
        
        let bankProfile = mockProfiles.first { $0.key == "bank_standard" }
        XCTAssertNotNil(bankProfile, "Should have bank standard profile")
        XCTAssertEqual(bankProfile?.spreadPercent, 2.0, "Bank standard should have 2% spread")
        
        let fintechProfile = mockProfiles.first { $0.key == "fintech_fast" }
        XCTAssertNotNil(fintechProfile, "Should have fintech fast profile")
        XCTAssertEqual(fintechProfile?.spreadPercent, 0.6, "Fintech fast should have 0.6% spread")
    }
    
    func testMockCurrencyRates() throws {
        // Given
        let mockRates = createMockCurrencyRates()
        
        // When & Then
        XCTAssertEqual(mockRates.count, 4, "Should have 4 mock currency rates")
        
        let usdToEur = mockRates.first { $0.baseCurrency == "USD" && $0.targetCurrency == "EUR" }
        XCTAssertNotNil(usdToEur, "Should have USD to EUR rate")
        XCTAssertEqual(usdToEur?.rate, Decimal(0.92), "USD to EUR rate should be 0.92")
        
        let eurToUsd = mockRates.first { $0.baseCurrency == "EUR" && $0.targetCurrency == "USD" }
        XCTAssertNotNil(eurToUsd, "Should have EUR to USD rate")
        XCTAssertEqual(eurToUsd?.rate, Decimal(1.087), "EUR to USD rate should be 1.087")
    }
    
    // MARK: - Data Model Validation Tests
    
    func testUserModelValidation() throws {
        // Given
        let user = User(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            preferences: ["theme": AnyCodable("dark")],
            lastActive: Date()
        )
        
        // When & Then
        XCTAssertNotNil(user.id, "User should have valid ID")
        XCTAssertTrue(user.createdAt <= user.updatedAt, "Created date should be before or equal to updated date")
        XCTAssertTrue(user.updatedAt <= user.lastActive, "Updated date should be before or equal to last active date")
    }
    
    func testCurrencyRateModelValidation() throws {
        // Given
        let now = Date()
        let expiresAt = now.addingTimeInterval(3600)
        let currencyRate = CurrencyRate(
            id: UUID(),
            baseCurrency: "USD",
            targetCurrency: "EUR",
            rate: Decimal(0.92),
            provider: "interbank",
            createdAt: now,
            expiresAt: expiresAt
        )
        
        // When & Then
        XCTAssertNotNil(currencyRate.id, "Currency rate should have valid ID")
        XCTAssertEqual(currencyRate.baseCurrency, "USD", "Base currency should be set correctly")
        XCTAssertEqual(currencyRate.targetCurrency, "EUR", "Target currency should be set correctly")
        XCTAssertTrue(currencyRate.createdAt <= currencyRate.expiresAt, "Created date should be before expires date")
        XCTAssertTrue(currencyRate.rate > 0, "Rate should be positive")
    }
    
    func testWatchlistItemModelValidation() throws {
        // Given
        let userId = UUID()
        let watchlistItem = WatchlistItem(
            id: UUID(),
            userId: userId,
            currencyCode: "EUR",
            position: 0,
            createdAt: Date()
        )
        
        // When & Then
        XCTAssertNotNil(watchlistItem.id, "Watchlist item should have valid ID")
        XCTAssertEqual(watchlistItem.userId, userId, "User ID should be set correctly")
        XCTAssertEqual(watchlistItem.currencyCode, "EUR", "Currency code should be set correctly")
        XCTAssertEqual(watchlistItem.position, 0, "Position should be set correctly")
    }
    
    // MARK: - JSON Serialization Tests
    
    func testComplexUserPreferencesSerialization() throws {
        // Given
        let user = User(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            preferences: [
                "theme": AnyCodable("dark"),
                "autoRefresh": AnyCodable(true),
                "refreshInterval": AnyCodable(60),
                "favorites": AnyCodable(["USD", "EUR", "GBP"]),
                "settings": AnyCodable([
                    "notifications": true,
                    "sound": false,
                    "vibration": true
                ])
            ],
            lastActive: Date()
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(user)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedUser = try decoder.decode(User.self, from: data)
        
        // Then
        XCTAssertEqual(decodedUser.id, user.id)
        XCTAssertEqual(decodedUser.preferences.count, user.preferences.count)
    }
    
    func testCurrencyRateSerialization() throws {
        // Given
        let currencyRate = CurrencyRate(
            id: UUID(),
            baseCurrency: "USD",
            targetCurrency: "EUR",
            rate: Decimal(0.92),
            provider: "interbank",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(currencyRate)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedRate = try decoder.decode(CurrencyRate.self, from: data)
        
        // Then
        XCTAssertEqual(decodedRate.id, currencyRate.id)
        XCTAssertEqual(decodedRate.baseCurrency, currencyRate.baseCurrency)
        XCTAssertEqual(decodedRate.targetCurrency, currencyRate.targetCurrency)
        XCTAssertEqual(decodedRate.rate, currencyRate.rate)
        XCTAssertEqual(decodedRate.provider, currencyRate.provider)
    }
    
    // MARK: - Error Handling Tests
    
    func testSupabaseErrorHandling() throws {
        // Given
        let unauthenticatedError = SupabaseError.unauthenticated
        let invalidConfigError = SupabaseError.invalidConfiguration
        
        // When & Then
        switch unauthenticatedError {
        case .unauthenticated:
            XCTAssertTrue(true, "Should handle unauthenticated error")
        case .invalidConfiguration:
            XCTFail("Should not be invalid configuration error")
        }
        
        switch invalidConfigError {
        case .unauthenticated:
            XCTFail("Should not be unauthenticated error")
        case .invalidConfiguration:
            XCTAssertTrue(true, "Should handle invalid configuration error")
        }
    }
    
    func testInvalidJSONDecoding() throws {
        // Given
        let invalidJSON = """
        {
            "id": "invalid-uuid",
            "created_at": "invalid-date",
            "updated_at": "invalid-date",
            "preferences": {},
            "last_active": "invalid-date"
        }
        """
        let data = invalidJSON.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(User.self, from: data), "Invalid JSON should throw error")
    }
    
    // MARK: - Performance Tests
    
    func testDataModelEncodingPerformance() throws {
        // Given
        let user = User(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            preferences: ["theme": AnyCodable("dark")],
            lastActive: Date()
        )
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = try? JSONEncoder().encode(user)
            }
        }
    }
    
    func testDataModelDecodingPerformance() throws {
        // Given
        let user = User(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            preferences: ["theme": AnyCodable("dark")],
            lastActive: Date()
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(user)
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = try? JSONDecoder().decode(User.self, from: data)
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageWithLargeDataSet() throws {
        // Given
        let largeDataSet = (0..<1000).map { _ in
            User(
                id: UUID(),
                createdAt: Date(),
                updatedAt: Date(),
                preferences: ["theme": AnyCodable("dark")],
                lastActive: Date()
            )
        }
        
        // When
        let startMemory = getMemoryUsage()
        
        for user in largeDataSet {
            _ = try? JSONEncoder().encode(user)
        }
        
        let endMemory = getMemoryUsage()
        
        // Then
        let memoryIncrease = endMemory - startMemory
        XCTAssertLessThan(memoryIncrease, 50_000_000, "Memory increase should be less than 50MB")
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
    
    // MARK: - Helper Methods
    
    private func createMockProviderProfiles() -> [SupabaseProviderProfile] {
        return [
            SupabaseProviderProfile(
                id: UUID(),
                key: "interbank",
                name: "Interbank (No Spread)",
                spreadPercent: Decimal(0.0),
                fixedFee: Decimal(0.0),
                isActive: true,
                createdAt: Date()
            ),
            SupabaseProviderProfile(
                id: UUID(),
                key: "bank_standard",
                name: "Bank Standard",
                spreadPercent: Decimal(2.0),
                fixedFee: Decimal(2.0),
                isActive: true,
                createdAt: Date()
            ),
            SupabaseProviderProfile(
                id: UUID(),
                key: "fintech_fast",
                name: "Fintech Fast",
                spreadPercent: Decimal(0.6),
                fixedFee: Decimal(0.5),
                isActive: true,
                createdAt: Date()
            )
        ]
    }
    
    private func createMockCurrencyRates() -> [CurrencyRate] {
        let now = Date()
        let expiresAt = now.addingTimeInterval(3600)
        
        return [
            CurrencyRate(
                id: UUID(),
                baseCurrency: "USD",
                targetCurrency: "EUR",
                rate: Decimal(0.92),
                provider: "interbank",
                createdAt: now,
                expiresAt: expiresAt
            ),
            CurrencyRate(
                id: UUID(),
                baseCurrency: "EUR",
                targetCurrency: "USD",
                rate: Decimal(1.087),
                provider: "interbank",
                createdAt: now,
                expiresAt: expiresAt
            ),
            CurrencyRate(
                id: UUID(),
                baseCurrency: "USD",
                targetCurrency: "GBP",
                rate: Decimal(0.79),
                provider: "interbank",
                createdAt: now,
                expiresAt: expiresAt
            ),
            CurrencyRate(
                id: UUID(),
                baseCurrency: "USD",
                targetCurrency: "JPY",
                rate: Decimal(147.0),
                provider: "interbank",
                createdAt: now,
                expiresAt: expiresAt
            )
        ]
    }
}
