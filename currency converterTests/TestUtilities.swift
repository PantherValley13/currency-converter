import Foundation
import XCTest
@testable import currency_converter

/// Test utilities and mock data for Currency Converter tests
final class TestUtilities {
    
    // MARK: - Mock Data
    
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
    
    // MARK: - Mock Provider Profiles
    
    static func createMockProviderProfiles() -> [SupabaseProviderProfile] {
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
    
    // MARK: - Mock Currency Rates
    
    static func createMockCurrencyRates() -> [CurrencyRate] {
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
    
    // MARK: - Mock Alert Rules
    
    static func createMockAlertRules() -> [CurrencyAlertRule] {
        return [
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
            ),
            CurrencyAlertRule(
                id: UUID(),
                base: "EUR",
                target: "USD",
                threshold: 1.10,
                direction: .above
            )
        ]
    }
    
    // MARK: - Mock Quick Pairs
    
    static func createMockQuickPairs() -> [CurrencyQuickPair] {
        return [
            CurrencyQuickPair(base: "USD", target: "EUR"),
            CurrencyQuickPair(base: "USD", target: "JPY"),
            CurrencyQuickPair(base: "EUR", target: "GBP"),
            CurrencyQuickPair(base: "GBP", target: "USD")
        ]
    }
    
    // MARK: - Mock Watchlist Items
    
    static func createMockWatchlistItems() -> [WatchlistItem] {
        let userId = UUID()
        let now = Date()
        
        return [
            WatchlistItem(
                id: UUID(),
                userId: userId,
                currencyCode: "EUR",
                position: 0,
                createdAt: now
            ),
            WatchlistItem(
                id: UUID(),
                userId: userId,
                currencyCode: "JPY",
                position: 1,
                createdAt: now
            ),
            WatchlistItem(
                id: UUID(),
                userId: userId,
                currencyCode: "GBP",
                position: 2,
                createdAt: now
            )
        ]
    }
    
    // MARK: - Mock Conversion History
    
    static func createMockConversionHistory() -> [ConversionHistory] {
        let userId = UUID()
        let now = Date()
        
        return [
            ConversionHistory(
                id: UUID(),
                userId: userId,
                baseCurrency: "USD",
                targetCurrency: "EUR",
                amount: Decimal(100.0),
                rate: Decimal(0.92),
                result: Decimal(92.0),
                provider: "interbank",
                createdAt: now
            ),
            ConversionHistory(
                id: UUID(),
                userId: userId,
                baseCurrency: "EUR",
                targetCurrency: "USD",
                amount: Decimal(100.0),
                rate: Decimal(1.087),
                result: Decimal(108.7),
                provider: "interbank",
                createdAt: now.addingTimeInterval(-3600)
            )
        ]
    }
    
    // MARK: - Mock User
    
    static func createMockUser() -> User {
        return User(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            preferences: [
                "theme": AnyCodable("dark"),
                "autoRefresh": AnyCodable(true),
                "refreshInterval": AnyCodable(60)
            ],
            lastActive: Date()
        )
    }
    
    // MARK: - Test Helper Functions
    
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
    
    // MARK: - JSON Test Helpers
    
    static func encodeToJSON<T: Codable>(_ object: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(object)
    }
    
    static func decodeFromJSON<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
    
    static func assertJSONEncoding<T: Codable>(
        _ object: T,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let data = try encodeToJSON(object)
        XCTAssertGreaterThan(data.count, 0, "Encoded data should not be empty", file: file, line: line)
    }
    
    static func assertJSONDecoding<T: Codable>(
        _ type: T.Type,
        from data: Data,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T {
        return try decodeFromJSON(type, from: data)
    }
    
    // MARK: - Async Test Helpers
    
    static func waitForAsyncOperation(
        timeout: TimeInterval = 10.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        // Helper for async operations that need time to complete
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
    
    // MARK: - Mock API Responses
    
    static func createMockRatesResponse() -> [String: Any] {
        return [
            "base": "USD",
            "rates": [
                "EUR": 0.92,
                "GBP": 0.79,
                "JPY": 147.0,
                "CAD": 1.35,
                "AUD": 1.49
            ],
            "date": "2023-01-01"
        ]
    }
    
    static func createMockTimeseriesResponse() -> [String: Any] {
        return [
            "rates": [
                "2023-01-01": ["EUR": 0.92],
                "2023-01-02": ["EUR": 0.93],
                "2023-01-03": ["EUR": 0.91]
            ]
        ]
    }
}
