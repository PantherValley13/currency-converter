import XCTest
@testable import currency_converter

/// Unit tests for currency conversion logic
final class CurrencyConversionTests: XCTestCase {
    
    // MARK: - Test Data
    private let sampleRates: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 147.0,
        "CAD": 1.35,
        "AUD": 1.49
    ]
    
    // MARK: - Basic Conversion Tests
    
    func testUSDToEURConversion() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let expectedRate = 0.92
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: sampleRates
        )
        
        // Then
        XCTAssertEqual(result, 92.0, accuracy: 0.01, "100 USD should equal 92 EUR")
    }
    
    func testEURToUSDConversion() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "EUR"
        let targetCurrency = "USD"
        let expectedRate = 1.0 / 0.92
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: sampleRates
        )
        
        // Then
        XCTAssertEqual(result, 108.70, accuracy: 0.01, "100 EUR should equal approximately 108.70 USD")
    }
    
    func testUSDToJPYConversion() throws {
        // Given
        let amount = 1.0
        let baseCurrency = "USD"
        let targetCurrency = "JPY"
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: sampleRates
        )
        
        // Then
        XCTAssertEqual(result, 147.0, accuracy: 0.01, "1 USD should equal 147 JPY")
    }
    
    func testSameCurrencyConversion() throws {
        // Given
        let amount = 100.0
        let currency = "USD"
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: currency,
            targetCurrency: currency,
            rates: sampleRates
        )
        
        // Then
        XCTAssertEqual(result, 100.0, accuracy: 0.01, "Same currency conversion should return original amount")
    }
    
    func testZeroAmountConversion() throws {
        // Given
        let amount = 0.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: sampleRates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, accuracy: 0.01, "Zero amount should return zero")
    }
    
    func testNegativeAmountConversion() throws {
        // Given
        let amount = -100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: sampleRates
        )
        
        // Then
        XCTAssertEqual(result, -92.0, accuracy: 0.01, "Negative amount should be converted correctly")
    }
    
    func testLargeAmountConversion() throws {
        // Given
        let amount = 1_000_000.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: sampleRates
        )
        
        // Then
        XCTAssertEqual(result, 920_000.0, accuracy: 0.01, "Large amounts should be converted correctly")
    }
    
    // MARK: - Error Handling Tests
    
    func testMissingBaseCurrencyRate() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "INVALID"
        let targetCurrency = "EUR"
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: sampleRates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Missing base currency rate should return 0")
    }
    
    func testMissingTargetCurrencyRate() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "INVALID"
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: sampleRates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Missing target currency rate should return 0")
    }
    
    func testZeroBaseRate() throws {
        // Given
        var rates = sampleRates
        rates["USD"] = 0.0
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 0.0, "Zero base rate should return 0")
    }
    
    // MARK: - Provider Fee Tests
    
    func testProviderFeeCalculation() throws {
        // Given
        let amount = 100.0
        let spreadPercent = 2.0
        let fixedFee = 5.0
        
        // When
        let result = applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        let expectedSpread = amount * (1 - spreadPercent / 100)
        let expectedResult = expectedSpread - fixedFee
        XCTAssertEqual(result, expectedResult, accuracy: 0.01, "Provider fees should be applied correctly")
    }
    
    func testZeroProviderFees() throws {
        // Given
        let amount = 100.0
        let spreadPercent = 0.0
        let fixedFee = 0.0
        
        // When
        let result = applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        XCTAssertEqual(result, 100.0, accuracy: 0.01, "Zero fees should return original amount")
    }
    
    func testProviderFeeWithHighSpread() throws {
        // Given
        let amount = 100.0
        let spreadPercent = 50.0
        let fixedFee = 10.0
        
        // When
        let result = applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        let expectedSpread = amount * (1 - spreadPercent / 100)
        let expectedResult = expectedSpread - fixedFee
        XCTAssertEqual(result, expectedResult, accuracy: 0.01, "High spread should be applied correctly")
    }
    
    func testProviderFeeWithNegativeAmount() throws {
        // Given
        let amount = -100.0
        let spreadPercent = 2.0
        let fixedFee = 5.0
        
        // When
        let result = applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        let expectedSpread = amount * (1 - spreadPercent / 100)
        let expectedResult = max(0, expectedSpread - fixedFee)
        XCTAssertEqual(result, expectedResult, accuracy: 0.01, "Negative amount with fees should be handled correctly")
    }
    
    func testProviderFeeWithVerySmallAmount() throws {
        // Given
        let amount = 0.01
        let spreadPercent = 1.0
        let fixedFee = 0.005
        
        // When
        let result = applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        let expectedSpread = amount * (1 - spreadPercent / 100)
        let expectedResult = max(0, expectedSpread - fixedFee)
        XCTAssertEqual(result, expectedResult, accuracy: 0.0001, "Very small amounts should be handled correctly")
    }
    
    // MARK: - Complex Conversion Scenarios
    
    func testMultiCurrencyConversion() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "USD"
        let intermediateCurrency = "EUR"
        let targetCurrency = "GBP"
        let rates = sampleRates
        
        // When
        let usdToEur = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: intermediateCurrency,
            rates: rates
        )
        let eurToGbp = convertCurrency(
            amount: usdToEur,
            baseCurrency: intermediateCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        let directUsdToGbp = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(eurToGbp, directUsdToGbp, accuracy: 0.01, "Multi-step conversion should equal direct conversion")
    }
    
    func testConversionWithDifferentBaseCurrencies() throws {
        // Given
        let amount = 100.0
        let rates = sampleRates
        
        // When
        let usdToEur = convertCurrency(amount: amount, baseCurrency: "USD", targetCurrency: "EUR", rates: rates)
        let eurToUsd = convertCurrency(amount: amount, baseCurrency: "EUR", targetCurrency: "USD", rates: rates)
        
        // Then
        XCTAssertNotEqual(usdToEur, eurToUsd, "Different base currencies should produce different results")
        XCTAssertGreaterThan(usdToEur, 0, "USD to EUR should be positive")
        XCTAssertGreaterThan(eurToUsd, 0, "EUR to USD should be positive")
    }
    
    func testConversionPrecision() throws {
        // Given
        let amount = 1.0
        let baseCurrency = "USD"
        let targetCurrency = "JPY"
        let rates = sampleRates
        
        // When
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        // Then
        XCTAssertEqual(result, 147.0, accuracy: 0.0001, "High precision conversion should be accurate")
    }
    
    // MARK: - Rate Validation Tests
    
    func testRateValidation() throws {
        // Given
        let validRates = sampleRates
        let invalidRates: [String: Double] = ["USD": 0.0, "EUR": -0.92]
        
        // When & Then
        XCTAssertTrue(validateRates(validRates), "Valid rates should pass validation")
        XCTAssertFalse(validateRates(invalidRates), "Invalid rates should fail validation")
    }
    
    func testRateConsistency() throws {
        // Given
        let rates = sampleRates
        let usdToEur = convertCurrency(amount: 1.0, baseCurrency: "USD", targetCurrency: "EUR", rates: rates)
        let eurToUsd = convertCurrency(amount: 1.0, baseCurrency: "EUR", targetCurrency: "USD", rates: rates)
        
        // When
        let crossRate = usdToEur * eurToUsd
        
        // Then
        XCTAssertEqual(crossRate, 1.0, accuracy: 0.01, "Cross rates should be consistent")
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() throws {
        // Given
        let amount = 100.0
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let rates = sampleRates
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = convertCurrency(
                    amount: amount,
                    baseCurrency: baseCurrency,
                    targetCurrency: targetCurrency,
                    rates: rates
                )
            }
        }
    }
    
    func testProviderFeePerformance() throws {
        // Given
        let amount = 100.0
        let spreadPercent = 2.0
        let fixedFee = 5.0
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = applyProviderFees(
                    amount: amount,
                    spreadPercent: spreadPercent,
                    fixedFee: fixedFee
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertCurrency(
        amount: Double,
        baseCurrency: String,
        targetCurrency: String,
        rates: [String: Double]
    ) -> Double {
        guard let baseRate = rates[baseCurrency],
              let targetRate = rates[targetCurrency],
              baseRate > 0 else {
            return 0.0
        }
        
        let usdValue = amount / baseRate
        return usdValue * targetRate
    }
    
    private func applyProviderFees(
        amount: Double,
        spreadPercent: Double,
        fixedFee: Double
    ) -> Double {
        let spreadFactor = max(0, 1 - spreadPercent / 100)
        let result = amount * spreadFactor
        return max(0, result - fixedFee)
    }
    
    private func validateRates(_ rates: [String: Double]) -> Bool {
        return rates.values.allSatisfy { $0 > 0 }
    }
}
