import XCTest
import SwiftUI
@testable import currency_converter

/// Unit tests for UI components and user interactions
final class UIComponentTests: XCTestCase {
    
    // MARK: - Currency Selection Tests
    
    func testCurrencySelectionMode() throws {
        // Given
        let baseMode = SelectionMode.base
        let targetMode = SelectionMode.target
        
        // When & Then
        XCTAssertEqual(baseMode.rawValue, "Base", "Base mode should have correct raw value")
        XCTAssertEqual(targetMode.rawValue, "Target", "Target mode should have correct raw value")
        
        XCTAssertEqual(baseMode.id, "Base", "Base mode should have correct id")
        XCTAssertEqual(targetMode.id, "Target", "Target mode should have correct id")
    }
    
    func testCurrencySelectionModeCases() throws {
        // Given
        let allCases = SelectionMode.allCases
        
        // When & Then
        XCTAssertEqual(allCases.count, 2, "Should have 2 selection modes")
        XCTAssertTrue(allCases.contains(.base), "Should contain base mode")
        XCTAssertTrue(allCases.contains(.target), "Should contain target mode")
    }
    
    // MARK: - Provider Profile Tests
    
    func testProviderProfileCreation() throws {
        // Given
        let key = "test_provider"
        let name = "Test Provider"
        let spreadPercent = 1.5
        let fixedFee = 2.0
        
        // When
        let profile = FXProviderProfile(
            key: key,
            name: name,
            spreadPercent: spreadPercent,
            fixedFee: fixedFee
        )
        
        // Then
        XCTAssertEqual(profile.key, key)
        XCTAssertEqual(profile.name, name)
        XCTAssertEqual(profile.spreadPercent, spreadPercent)
        XCTAssertEqual(profile.fixedFee, fixedFee)
        XCTAssertEqual(profile.id, key, "ID should equal key")
    }
    
    func testProviderProfileEquality() throws {
        // Given
        let profile1 = FXProviderProfile(
            key: "test",
            name: "Test",
            spreadPercent: 1.0,
            fixedFee: 2.0
        )
        let profile2 = FXProviderProfile(
            key: "test",
            name: "Test",
            spreadPercent: 1.0,
            fixedFee: 2.0
        )
        let profile3 = FXProviderProfile(
            key: "different",
            name: "Different",
            spreadPercent: 1.0,
            fixedFee: 2.0
        )
        
        // When & Then
        XCTAssertEqual(profile1, profile2, "Identical profiles should be equal")
        XCTAssertNotEqual(profile1, profile3, "Different profiles should not be equal")
    }
    
    // MARK: - Quick Pair Tests
    
    func testQuickPairCreation() throws {
        // Given
        let base = "USD"
        let target = "EUR"
        
        // When
        let quickPair = CurrencyQuickPair(base: base, target: target)
        
        // Then
        XCTAssertEqual(quickPair.base, base)
        XCTAssertEqual(quickPair.target, target)
        XCTAssertEqual(quickPair.id, "\(base)→\(target)", "ID should be formatted correctly")
    }
    
    func testQuickPairEquality() throws {
        // Given
        let pair1 = CurrencyQuickPair(base: "USD", target: "EUR")
        let pair2 = CurrencyQuickPair(base: "USD", target: "EUR")
        let pair3 = CurrencyQuickPair(base: "EUR", target: "USD")
        
        // When & Then
        XCTAssertEqual(pair1, pair2, "Identical pairs should be equal")
        XCTAssertNotEqual(pair1, pair3, "Different pairs should not be equal")
    }
    
    func testQuickPairHashable() throws {
        // Given
        let pair1 = CurrencyQuickPair(base: "USD", target: "EUR")
        let pair2 = CurrencyQuickPair(base: "USD", target: "EUR")
        
        // When & Then
        XCTAssertEqual(pair1.hashValue, pair2.hashValue, "Identical pairs should have same hash value")
    }
    
    // MARK: - Alert Rule Tests
    
    func testAlertRuleDirection() throws {
        // Given
        let aboveDirection = CurrencyAlertRule.Direction.above
        let belowDirection = CurrencyAlertRule.Direction.below
        
        // When & Then
        XCTAssertEqual(aboveDirection.rawValue, "above", "Above direction should have correct raw value")
        XCTAssertEqual(belowDirection.rawValue, "below", "Below direction should have correct raw value")
        
        XCTAssertEqual(aboveDirection.id, "above", "Above direction should have correct id")
        XCTAssertEqual(belowDirection.id, "below", "Below direction should have correct id")
    }
    
    func testAlertRuleDirectionCases() throws {
        // Given
        let allCases = CurrencyAlertRule.Direction.allCases
        
        // When & Then
        XCTAssertEqual(allCases.count, 2, "Should have 2 alert directions")
        XCTAssertTrue(allCases.contains(.above), "Should contain above direction")
        XCTAssertTrue(allCases.contains(.below), "Should contain below direction")
    }
    
    func testAlertRuleCreation() throws {
        // Given
        let id = UUID()
        let base = "USD"
        let target = "EUR"
        let threshold = 0.95
        let direction = CurrencyAlertRule.Direction.above
        
        // When
        let alertRule = CurrencyAlertRule(
            id: id,
            base: base,
            target: target,
            threshold: threshold,
            direction: direction
        )
        
        // Then
        XCTAssertEqual(alertRule.id, id)
        XCTAssertEqual(alertRule.base, base)
        XCTAssertEqual(alertRule.target, target)
        XCTAssertEqual(alertRule.threshold, threshold)
        XCTAssertEqual(alertRule.direction, direction)
    }
    
    func testAlertRuleEquality() throws {
        // Given
        let id = UUID()
        let alertRule1 = CurrencyAlertRule(
            id: id,
            base: "USD",
            target: "EUR",
            threshold: 0.95,
            direction: .above
        )
        let alertRule2 = CurrencyAlertRule(
            id: id,
            base: "USD",
            target: "EUR",
            threshold: 0.95,
            direction: .above
        )
        let alertRule3 = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.95,
            direction: .above
        )
        
        // When & Then
        XCTAssertEqual(alertRule1, alertRule2, "Identical alert rules should be equal")
        XCTAssertNotEqual(alertRule1, alertRule3, "Different alert rules should not be equal")
    }
    
    // MARK: - History Range Tests
    
    func testHistoryRangeCases() throws {
        // Given
        let allCases = HistoryRange.allCases
        
        // When & Then
        XCTAssertEqual(allCases.count, 5, "Should have 5 history ranges")
        XCTAssertTrue(allCases.contains(.d7), "Should contain 7D range")
        XCTAssertTrue(allCases.contains(.m1), "Should contain 1M range")
        XCTAssertTrue(allCases.contains(.m3), "Should contain 3M range")
        XCTAssertTrue(allCases.contains(.ytd), "Should contain YTD range")
        XCTAssertTrue(allCases.contains(.y1), "Should contain 1Y range")
    }
    
    func testHistoryRangeRawValues() throws {
        // Given
        let d7 = HistoryRange.d7
        let m1 = HistoryRange.m1
        let m3 = HistoryRange.m3
        let ytd = HistoryRange.ytd
        let y1 = HistoryRange.y1
        
        // When & Then
        XCTAssertEqual(d7.rawValue, "7D", "7D should have correct raw value")
        XCTAssertEqual(m1.rawValue, "1M", "1M should have correct raw value")
        XCTAssertEqual(m3.rawValue, "3M", "3M should have correct raw value")
        XCTAssertEqual(ytd.rawValue, "YTD", "YTD should have correct raw value")
        XCTAssertEqual(y1.rawValue, "1Y", "1Y should have correct raw value")
    }
    
    func testHistoryRangeIds() throws {
        // Given
        let d7 = HistoryRange.d7
        let m1 = HistoryRange.m1
        let m3 = HistoryRange.m3
        let ytd = HistoryRange.ytd
        let y1 = HistoryRange.y1
        
        // When & Then
        XCTAssertEqual(d7.id, "7D", "7D should have correct id")
        XCTAssertEqual(m1.id, "1M", "1M should have correct id")
        XCTAssertEqual(m3.id, "3M", "3M should have correct id")
        XCTAssertEqual(ytd.id, "YTD", "YTD should have correct id")
        XCTAssertEqual(y1.id, "1Y", "1Y should have correct id")
    }
    
    // MARK: - Rate Point Tests
    
    func testRatePointCreation() throws {
        // Given
        let date = Date()
        let value = 0.92
        
        // When
        let ratePoint = RatePoint(date: date, value: value)
        
        // Then
        XCTAssertEqual(ratePoint.date, date)
        XCTAssertEqual(ratePoint.value, value)
        XCTAssertNotNil(ratePoint.id, "Rate point should have an ID")
    }
    
    func testRatePointIdentifiable() throws {
        // Given
        let ratePoint1 = RatePoint(date: Date(), value: 0.92)
        let ratePoint2 = RatePoint(date: Date(), value: 0.93)
        
        // When & Then
        XCTAssertNotEqual(ratePoint1.id, ratePoint2.id, "Different rate points should have different IDs")
    }
    
    // MARK: - Mock Data Tests
    
    func testMockCurrencies() throws {
        // Given
        let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "BRL", "ZAR", "SEK"]
        
        // When & Then
        XCTAssertEqual(currencies.count, 12, "Should have 12 currencies")
        XCTAssertTrue(currencies.contains("USD"), "Should contain USD")
        XCTAssertTrue(currencies.contains("EUR"), "Should contain EUR")
        XCTAssertTrue(currencies.contains("GBP"), "Should contain GBP")
        XCTAssertTrue(currencies.contains("JPY"), "Should contain JPY")
    }
    
    func testMockCurrencyNames() throws {
        // Given
        let currencyNames = [
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
        
        // When & Then
        XCTAssertEqual(currencyNames.count, 12, "Should have 12 currency names")
        XCTAssertEqual(currencyNames["USD"], "US Dollar", "USD should have correct name")
        XCTAssertEqual(currencyNames["EUR"], "Euro", "EUR should have correct name")
        XCTAssertEqual(currencyNames["GBP"], "British Pound", "GBP should have correct name")
        XCTAssertEqual(currencyNames["JPY"], "Japanese Yen", "JPY should have correct name")
    }
    
    func testMockDefaultRates() throws {
        // Given
        let defaultRates = [
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
        
        // When & Then
        XCTAssertEqual(defaultRates.count, 12, "Should have 12 default rates")
        XCTAssertEqual(defaultRates["USD"], 1.0, "USD should have rate 1.0")
        XCTAssertEqual(defaultRates["EUR"], 0.92, "EUR should have rate 0.92")
        XCTAssertEqual(defaultRates["GBP"], 0.79, "GBP should have rate 0.79")
        XCTAssertEqual(defaultRates["JPY"], 147.0, "JPY should have rate 147.0")
    }
    
    // MARK: - Helper Types
    
    private enum HistoryRange: String, CaseIterable, Identifiable {
        case d7 = "7D"
        case m1 = "1M"
        case m3 = "3M"
        case ytd = "YTD"
        case y1 = "1Y"
        
        var id: String { rawValue }
    }
    
    private struct RatePoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
}
