import Foundation
import XCTest

/// Test configuration and setup for Currency Converter tests
final class TestConfiguration {
    
    // MARK: - Test Constants
    
    static let testTimeout: TimeInterval = 10.0
    static let performanceTestIterations = 1000
    static let memoryTestThreshold: UInt64 = 10_000_000 // 10MB
    
    // MARK: - Test Environment Setup
    
    static func setupTestEnvironment() {
        // Set up any test-specific environment variables
        ProcessInfo.processInfo.environment["TEST_MODE"] = "true"
        ProcessInfo.processInfo.environment["SUPABASE_URL"] = "https://test.supabase.co"
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] = "test-key"
    }
    
    static func teardownTestEnvironment() {
        // Clean up test environment
        // This is called after each test
    }
    
    // MARK: - Mock Data Configuration
    
    static let mockCurrencies = [
        "USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "BRL", "ZAR", "SEK"
    ]
    
    static let mockCurrencyNames = [
        "USD": "US Dollar",
        "EUR": "Euro",
        "GBP": "British Pound",
        "JPY": "Japanese Yen",
        "CAD": "Canadian Dollar",
        "AUD": "Australian Dollar",
        "CHF": "Swiss Franc",
        "CNY": "Chinese Yuan",
        "INR": "Indian Rupee",
        "BRL": "Brazilian Real",
        "ZAR": "South African Rand",
        "SEK": "Swedish Krona"
    ]
    
    static let mockExchangeRates: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 147.0,
        "CAD": 1.35,
        "AUD": 1.49,
        "CHF": 0.88,
        "CNY": 7.25,
        "INR": 83.0,
        "BRL": 5.35,
        "ZAR": 18.4,
        "SEK": 10.9
    ]
    
    // MARK: - Test Assertions
    
    static func assertCurrencyConversion(
        amount: Double,
        baseCurrency: String,
        targetCurrency: String,
        expectedResult: Double,
        rates: [String: Double],
        accuracy: Double = 0.01,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = convertCurrency(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rates: rates
        )
        
        XCTAssertEqual(
            result,
            expectedResult,
            accuracy: accuracy,
            "Currency conversion failed for \(amount) \(baseCurrency) to \(targetCurrency)",
            file: file,
            line: line
        )
    }
    
    static func assertProviderFeeCalculation(
        amount: Double,
        spreadPercent: Double,
        fixedFee: Double,
        expectedResult: Double,
        accuracy: Double = 0.01,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = applyProviderFees(
            amount: amount,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        XCTAssertEqual(
            result,
            expectedResult,
            accuracy: accuracy,
            "Provider fee calculation failed for amount: \(amount), spread: \(spreadPercent)%, fee: \(fixedFee)",
            file: file,
            line: line
        )
    }
    
    static func assertAlertRuleEvaluation(
        alertRule: CurrencyAlertRule,
        currentRate: Double,
        expectedTriggered: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let isTriggered = evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        XCTAssertEqual(
            isTriggered,
            expectedTriggered,
            "Alert rule evaluation failed for rate: \(currentRate), threshold: \(alertRule.threshold), direction: \(alertRule.direction)",
            file: file,
            line: line
        )
    }
    
    // MARK: - Core Business Logic Functions
    
    static func convertCurrency(
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
    
    static func applyProviderFees(
        amount: Double,
        spreadPercent: Double,
        fixedFee: Double
    ) -> Double {
        let spreadFactor = max(0, 1 - spreadPercent / 100)
        let result = amount * spreadFactor
        return max(0, result - fixedFee)
    }
    
    static func evaluateAlert(alertRule: CurrencyAlertRule, currentRate: Double) -> Bool {
        switch alertRule.direction {
        case .above:
            return currentRate >= alertRule.threshold
        case .below:
            return currentRate <= alertRule.threshold
        }
    }
    
    // MARK: - Test Data Generation
    
    static func generateRandomRates(count: Int) -> [String: Double] {
        var rates: [String: Double] = [:]
        for i in 0..<count {
            rates["CURRENCY\(i)"] = Double.random(in: 0.1...100.0)
        }
        return rates
    }
    
    static func generateRandomAlertRules(count: Int) -> [CurrencyAlertRule] {
        var rules: [CurrencyAlertRule] = []
        for _ in 0..<count {
            let rule = CurrencyAlertRule(
                id: UUID(),
                base: mockCurrencies.randomElement() ?? "USD",
                target: mockCurrencies.randomElement() ?? "EUR",
                threshold: Double.random(in: 0.1...10.0),
                direction: Bool.random() ? .above : .below
            )
            rules.append(rule)
        }
        return rules
    }
    
    // MARK: - Performance Testing
    
    static func measurePerformance<T>(
        operation: () throws -> T,
        iterations: Int = performanceTestIterations
    ) rethrows -> (result: T, averageTime: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var result: T?
        for _ in 0..<iterations {
            result = try operation()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(iterations)
        
        return (result: result!, averageTime: averageTime)
    }
    
    // MARK: - Memory Testing
    
    static func measureMemoryUsage<T>(
        operation: () throws -> T
    ) rethrows -> (result: T, memoryUsage: UInt64) {
        let startMemory = getCurrentMemoryUsage()
        let result = try operation()
        let endMemory = getCurrentMemoryUsage()
        
        return (result: result, memoryUsage: endMemory - startMemory)
    }
    
    private static func getCurrentMemoryUsage() -> UInt64 {
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

// MARK: - Test Extensions

extension XCTestCase {
    
    func assertThrows<T>(
        _ expression: @autoclosure () throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line)
    }
    
    func assertNoThrow<T>(
        _ expression: @autoclosure () throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertNoThrow(try expression(), file: file, line: line)
    }
    
    func assertAsyncNoThrow<T>(
        _ expression: @autoclosure () async throws -> T,
        timeout: TimeInterval = TestConfiguration.testTimeout,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await XCTAssertNoThrowAsync(try await expression(), timeout: timeout, file: file, line: line)
    }
    
    func assertAsyncThrows<T>(
        _ expression: @autoclosure () async throws -> T,
        timeout: TimeInterval = TestConfiguration.testTimeout,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await XCTAssertThrowsErrorAsync(try await expression(), timeout: timeout, file: file, line: line)
    }
}

// MARK: - Async Test Helpers

func XCTAssertNoThrowAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    timeout: TimeInterval = TestConfiguration.testTimeout,
    file: StaticString = #file,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
    } catch {
        XCTFail("Expected no error, but got: \(error)", file: file, line: line)
    }
}

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    timeout: TimeInterval = TestConfiguration.testTimeout,
    file: StaticString = #file,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error, but none was thrown", file: file, line: line)
    } catch {
        // Expected error
    }
}
