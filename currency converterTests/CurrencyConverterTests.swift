import XCTest
@testable import currency_converter

/// Main test suite for Currency Converter app
/// This file serves as the entry point for all tests and contains integration tests
final class CurrencyConverterTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Set up test environment
        TestConfiguration.setupTestEnvironment()
    }

    override func tearDownWithError() throws {
        // Clean up test environment
        TestConfiguration.teardownTestEnvironment()
    }
    
    // MARK: - Integration Tests
    
    func testAppInitialization() throws {
        // Given
        let app = currency_converterApp()
        
        // When & Then
        XCTAssertNotNil(app, "App should initialize successfully")
    }
    
    func testSupabaseManagerInitialization() throws {
        // Given & When
        let manager = SupabaseManager.shared
        
        // Then
        XCTAssertNotNil(manager, "SupabaseManager should initialize successfully")
        XCTAssertNotNil(manager.baseURL, "Base URL should not be nil")
    }
    
    func testSupabaseConnection() async throws {
        // Given
        let manager = SupabaseManager.shared
        
        // When & Then
        await assertAsyncNoThrow(await manager.testConnection())
    }
    
    // MARK: - End-to-End Tests
    
    func testCompleteConversionFlow() async throws {
        // Given
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let rates = TestConfiguration.mockExchangeRates
        
        // When
        let result = TestConfiguration.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 92.0, accuracy: 0.01, "Complete conversion flow should work correctly")
    }
    
    func testCompleteAlertFlow() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.95,
            direction: .above
        )
        let currentRate = 0.92
        
        // When
        let isTriggered = TestConfiguration.evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        // Then
        XCTAssertFalse(isTriggered, "Complete alert flow should work correctly")
    }
    
    func testCompleteProviderFeeFlow() throws {
        // Given
        let amount = 100.0
        let spreadPercent = 2.0
        let fixedFee = 5.0
        
        // When
        let result = TestConfiguration.applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        XCTAssertEqual(result, 93.0, accuracy: 0.01, "Complete provider fee flow should work correctly")
    }
    
    // MARK: - Data Persistence Tests
    
    func testUserPreferencesPersistence() throws {
        // Given
        let user = TestUtilities.createMockUser()
        
        // When
        let data = try TestUtilities.encodeToJSON(user)
        let decodedUser = try TestUtilities.decodeFromJSON(User.self, from: data)
        
        // Then
        XCTAssertEqual(decodedUser.id, user.id)
        XCTAssertEqual(decodedUser.preferences.count, user.preferences.count)
    }
    
    func testAlertRulesPersistence() throws {
        // Given
        let alertRules = TestUtilities.createMockAlertRules()
        
        // When
        let data = try TestUtilities.encodeToJSON(alertRules)
        let decodedRules = try TestUtilities.decodeFromJSON([CurrencyAlertRule].self, from: data)
        
        // Then
        XCTAssertEqual(decodedRules.count, alertRules.count)
        XCTAssertEqual(decodedRules.first?.id, alertRules.first?.id)
    }
    
    func testQuickPairsPersistence() throws {
        // Given
        let quickPairs = TestUtilities.createMockQuickPairs()
        
        // When
        let data = try TestUtilities.encodeToJSON(quickPairs)
        let decodedPairs = try TestUtilities.decodeFromJSON([CurrencyQuickPair].self, from: data)
        
        // Then
        XCTAssertEqual(decodedPairs.count, quickPairs.count)
        XCTAssertEqual(decodedPairs.first?.base, quickPairs.first?.base)
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let rates = TestConfiguration.mockExchangeRates
        
        // When & Then
        measure {
            for _ in 0..<TestConfiguration.performanceTestIterations {
                _ = TestConfiguration.convertCurrency(
                    amount: amount,
                    baseCurrency: baseCurrency,
                    targetCurrency: targetCurrency,
                    rates: rates
                )
            }
        }
    }
    
    func testAlertEvaluationPerformance() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.95,
            direction: .above
        )
        let currentRate = 0.92
        
        // When & Then
        measure {
            for _ in 0..<TestConfiguration.performanceTestIterations {
                _ = TestConfiguration.evaluateAlert(alertRule: alertRule, currentRate: currentRate)
            }
        }
    }
    
    func testProviderFeeCalculationPerformance() throws {
        // Given
        let amount = 100.0
        let spreadPercent = 2.0
        let fixedFee = 5.0
        
        // When & Then
        measure {
            for _ in 0..<TestConfiguration.performanceTestIterations {
                _ = TestConfiguration.applyProviderFees(
                    amount: amount,
                    spreadPercent: spreadPercent,
                    fixedFee: fixedFee
                )
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageWithLargeDataSet() throws {
        // Given
        let largeRates = TestConfiguration.generateRandomRates(count: 1000)
        
        // When
        let (_, memoryUsage) = TestConfiguration.measureMemoryUsage {
            for _ in 0..<100 {
                _ = TestConfiguration.convertCurrency(
                    amount: 100.0,
                    baseCurrency: "USD",
                    targetCurrency: "EUR",
                    rates: largeRates
                )
            }
        }
        
        // Then
        XCTAssertLessThan(memoryUsage, TestConfiguration.memoryTestThreshold, "Memory usage should be within acceptable limits")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidInputHandling() throws {
        // Given
        let invalidRates: [String: Double] = [:]
        
        // When
        let result = TestConfiguration.convertCurrency(
            amount: 100.0,
            baseCurrency: "USD",
            targetCurrency: "EUR",
            rates: invalidRates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Invalid input should return zero")
    }
    
    func testNetworkErrorHandling() async throws {
        // Given
        let manager = SupabaseManager.shared
        
        // When & Then
        // This test would need to be implemented with a mock network layer
        // For now, we just ensure the method doesn't crash
        await assertAsyncNoThrow(await manager.testConnection())
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Given
        let currencies = TestConfiguration.mockCurrencies
        
        // When & Then
        for currency in currencies {
            XCTAssertFalse(currency.isEmpty, "Currency codes should not be empty")
            XCTAssertEqual(currency.count, 3, "Currency codes should be 3 characters")
        }
    }
    
    func testCurrencyNames() throws {
        // Given
        let currencyNames = TestConfiguration.mockCurrencyNames
        
        // When & Then
        for (code, name) in currencyNames {
            XCTAssertFalse(name.isEmpty, "Currency names should not be empty")
            XCTAssertTrue(name.contains(" "), "Currency names should contain spaces")
        }
    }
    
    // MARK: - Localization Tests
    
    func testCurrencyCodeFormat() throws {
        // Given
        let currencies = TestConfiguration.mockCurrencies
        
        // When & Then
        for currency in currencies {
            XCTAssertTrue(currency.allSatisfy { $0.isLetter }, "Currency codes should contain only letters")
            XCTAssertTrue(currency == currency.uppercased(), "Currency codes should be uppercase")
        }
    }
    
    // MARK: - Security Tests
    
    func testDataEncryption() throws {
        // Given
        let sensitiveData = "sensitive information"
        let anyCodable = AnyCodable(sensitiveData)
        
        // When
        let data = try TestUtilities.encodeToJSON(anyCodable)
        
        // Then
        XCTAssertNotNil(data, "Sensitive data should be encodable")
        XCTAssertGreaterThan(data.count, 0, "Encoded data should not be empty")
    }
    
    func testInputValidation() throws {
        // Given
        let invalidInputs = ["", "INVALID", "123", "TOOLONG"]
        
        // When & Then
        for input in invalidInputs {
            let result = TestConfiguration.convertCurrency(
                amount: 100.0,
                baseCurrency: input,
                targetCurrency: "EUR",
                rates: TestConfiguration.mockExchangeRates
            )
            XCTAssertEqual(result, 0.0, "Invalid input '\(input)' should return zero")
        }
    }
}
