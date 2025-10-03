import XCTest
@testable import currency_converter

/// Tests for edge cases and error conditions
final class EdgeCaseTests: XCTestCase {
    
    // MARK: - Extreme Value Tests
    
    func testVeryLargeAmountConversion() throws {
        // Given
        let amount = 1_000_000_000.0 // 1 billion
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let rates = TestUtilities.mockExchangeRates
        
        // When
        let result = TestUtilities.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 920_000_000.0, accuracy: 0.01, "Very large amounts should convert correctly")
    }
    
    func testVerySmallAmountConversion() throws {
        // Given
        let amount = 0.000001 // 1 micro-unit
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let rates = TestUtilities.mockExchangeRates
        
        // When
        let result = TestUtilities.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 0.00000092, accuracy: 0.00000001, "Very small amounts should convert correctly")
    }
    
    func testZeroAmountConversion() throws {
        // Given
        let amount = 0.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let rates = TestUtilities.mockExchangeRates
        
        // When
        let result = TestUtilities.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Zero amount should return zero")
    }
    
    func testNegativeAmountConversion() throws {
        // Given
        let amount = -100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let rates = TestUtilities.mockExchangeRates
        
        // When
        let result = TestUtilities.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, -92.0, accuracy: 0.01, "Negative amounts should convert correctly")
    }
    
    // MARK: - Invalid Input Tests
    
    func testInvalidCurrencyCode() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "INVALID"
        let targetCurrency = "EUR"
        let rates = TestUtilities.mockExchangeRates
        
        // When
        let result = TestUtilities.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Invalid currency should return zero")
    }
    
    func testEmptyCurrencyCode() throws {
        // Given
        let amount = 100.0
        let baseCurrency = ""
        let targetCurrency = "EUR"
        let rates = TestUtilities.mockExchangeRates
        
        // When
        let result = TestUtilities.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Empty currency should return zero")
    }
    
    func testNilRates() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let rates: [String: Double] = [:]
        
        // When
        let result = TestUtilities.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Empty rates should return zero")
    }
    
    func testZeroRate() throws {
        // Given
        var rates = TestUtilities.mockExchangeRates
        rates["USD"] = 0.0
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        
        // When
        let result = TestUtilities.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Zero rate should return zero")
    }
    
    func testNegativeRate() throws {
        // Given
        var rates = TestUtilities.mockExchangeRates
        rates["USD"] = -1.0
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        
        // When
        let result = TestUtilities.convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Negative rate should return zero")
    }
    
    // MARK: - Provider Fee Edge Cases
    
    func testVeryHighSpreadPercent() throws {
        // Given
        let amount = 100.0
        let spreadPercent = 100.0 // 100% spread
        let fixedFee = 0.0
        
        // When
        let result = TestUtilities.applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "100% spread should result in zero amount")
    }
    
    func testVeryHighFixedFee() throws {
        // Given
        let amount = 100.0
        let spreadPercent = 0.0
        let fixedFee = 200.0 // Higher than amount
        
        // When
        let result = TestUtilities.applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Fixed fee higher than amount should result in zero")
    }
    
    func testNegativeSpreadPercent() throws {
        // Given
        let amount = 100.0
        let spreadPercent = -10.0 // Negative spread
        let fixedFee = 0.0
        
        // When
        let result = TestUtilities.applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        XCTAssertEqual(result, 110.0, accuracy: 0.01, "Negative spread should increase amount")
    }
    
    func testNegativeFixedFee() throws {
        // Given
        let amount = 100.0
        let spreadPercent = 0.0
        let fixedFee = -10.0 // Negative fee (bonus)
        
        // When
        let result = TestUtilities.applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        XCTAssertEqual(result, 110.0, accuracy: 0.01, "Negative fixed fee should increase amount")
    }
    
    // MARK: - Alert Rule Edge Cases
    
    func testAlertRuleWithZeroThreshold() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.0,
            direction: .above
        )
        let currentRate = 0.0
        
        // When
        let isTriggered = TestUtilities.evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        // Then
        XCTAssertTrue(isTriggered, "Alert with zero threshold should trigger at zero rate")
    }
    
    func testAlertRuleWithNegativeThreshold() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: -0.1,
            direction: .below
        )
        let currentRate = 0.0
        
        // When
        let isTriggered = TestUtilities.evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        // Then
        XCTAssertTrue(isTriggered, "Alert with negative threshold should trigger at zero rate")
    }
    
    func testAlertRuleWithVeryHighThreshold() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 1000.0,
            direction: .above
        )
        let currentRate = 0.92
        
        // When
        let isTriggered = TestUtilities.evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        // Then
        XCTAssertFalse(isTriggered, "Alert with very high threshold should not trigger at normal rate")
    }
    
    // MARK: - Data Model Edge Cases
    
    func testUserWithEmptyPreferences() throws {
        // Given
        let user = User(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            preferences: [:],
            lastActive: Date()
        )
        
        // When
        let data = try TestUtilities.encodeToJSON(user)
        let decodedUser = try TestUtilities.decodeFromJSON(User.self, from: data)
        
        // Then
        XCTAssertEqual(decodedUser.id, user.id)
        XCTAssertEqual(decodedUser.preferences.count, 0)
    }
    
    func testUserWithComplexPreferences() throws {
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
        let data = try TestUtilities.encodeToJSON(user)
        let decodedUser = try TestUtilities.decodeFromJSON(User.self, from: data)
        
        // Then
        XCTAssertEqual(decodedUser.id, user.id)
        XCTAssertEqual(decodedUser.preferences.count, 5)
    }
    
    func testCurrencyRateWithVeryHighRate() throws {
        // Given
        let currencyRate = CurrencyRate(
            id: UUID(),
            baseCurrency: "USD",
            targetCurrency: "JPY",
            rate: Decimal(1000000.0), // Very high rate
            provider: "interbank",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        // When
        let data = try TestUtilities.encodeToJSON(currencyRate)
        let decodedRate = try TestUtilities.decodeFromJSON(CurrencyRate.self, from: data)
        
        // Then
        XCTAssertEqual(decodedRate.id, currencyRate.id)
        XCTAssertEqual(decodedRate.rate, Decimal(1000000.0))
    }
    
    func testCurrencyRateWithVerySmallRate() throws {
        // Given
        let currencyRate = CurrencyRate(
            id: UUID(),
            baseCurrency: "USD",
            targetCurrency: "JPY",
            rate: Decimal(0.000001), // Very small rate
            provider: "interbank",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        // When
        let data = try TestUtilities.encodeToJSON(currencyRate)
        let decodedRate = try TestUtilities.decodeFromJSON(CurrencyRate.self, from: data)
        
        // Then
        XCTAssertEqual(decodedRate.id, currencyRate.id)
        XCTAssertEqual(decodedRate.rate, Decimal(0.000001))
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let rates = TestUtilities.mockExchangeRates
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = TestUtilities.convertCurrency(
                    amount: amount,
                    baseCurrency: baseCurrency,
                    targetCurrency: targetCurrency,
                    rates: rates
                )
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
            for _ in 0..<1000 {
                _ = TestUtilities.applyProviderFees(
                    amount: amount,
                    spreadPercent: spreadPercent,
                    fixedFee: fixedFee
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
            for _ in 0..<1000 {
                _ = TestUtilities.evaluateAlert(alertRule: alertRule, currentRate: currentRate)
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageWithLargeDataSet() throws {
        // Given
        let largeRates = (0..<1000).reduce(into: [String: Double]()) { rates, index in
            rates["CURRENCY\(index)"] = Double.random(in: 0.1...100.0)
        }
        
        // When
        let startMemory = getMemoryUsage()
        
        for _ in 0..<100 {
            _ = TestUtilities.convertCurrency(
                amount: 100.0,
                baseCurrency: "USD",
                targetCurrency: "EUR",
                rates: largeRates
            )
        }
        
        let endMemory = getMemoryUsage()
        
        // Then
        let memoryIncrease = endMemory - startMemory
        XCTAssertLessThan(memoryIncrease, 10_000_000, "Memory increase should be less than 10MB") // 10MB
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
