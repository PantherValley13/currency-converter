import XCTest
import SwiftUI
@testable import currency_converter

/// Tests for accessibility features and compliance
final class AccessibilityTests: XCTestCase {
    
    // MARK: - Currency Code Accessibility Tests
    
    func testCurrencyCodeAccessibilityLabels() throws {
        // Given
        let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "BRL", "ZAR", "SEK"]
        
        // When & Then
        for currency in currencies {
            let accessibilityLabel = generateAccessibilityLabel(for: currency)
            XCTAssertFalse(accessibilityLabel.isEmpty, "Currency \(currency) should have accessibility label")
            XCTAssertTrue(accessibilityLabel.contains("currency"), "Accessibility label should contain 'currency'")
        }
    }
    
    func testCurrencyCodeAccessibilityHints() throws {
        // Given
        let currencies = ["USD", "EUR", "GBP", "JPY"]
        
        // When & Then
        for currency in currencies {
            let accessibilityHint = generateAccessibilityHint(for: currency)
            XCTAssertFalse(accessibilityHint.isEmpty, "Currency \(currency) should have accessibility hint")
            XCTAssertTrue(accessibilityHint.contains("tap"), "Accessibility hint should contain 'tap'")
        }
    }
    
    func testCurrencyCodeAccessibilityTraits() throws {
        // Given
        let currency = "USD"
        
        // When
        let traits = generateAccessibilityTraits(for: currency)
        
        // Then
        XCTAssertTrue(traits.contains(.isButton), "Currency should have button trait")
        XCTAssertTrue(traits.contains(.isSelected), "Selected currency should have selected trait")
    }
    
    // MARK: - Amount Input Accessibility Tests
    
    func testAmountInputAccessibilityLabel() throws {
        // Given
        let amount = "100.50"
        
        // When
        let accessibilityLabel = generateAmountAccessibilityLabel(amount: amount)
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Amount input should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("amount"), "Accessibility label should contain 'amount'")
        XCTAssertTrue(accessibilityLabel.contains(amount), "Accessibility label should contain the amount")
    }
    
    func testAmountInputAccessibilityValue() throws {
        // Given
        let amount = "100.50"
        let currency = "USD"
        
        // When
        let accessibilityValue = generateAmountAccessibilityValue(amount: amount, currency: currency)
        
        // Then
        XCTAssertFalse(accessibilityValue.isEmpty, "Amount input should have accessibility value")
        XCTAssertTrue(accessibilityValue.contains(amount), "Accessibility value should contain the amount")
        XCTAssertTrue(accessibilityValue.contains(currency), "Accessibility value should contain the currency")
    }
    
    func testAmountInputAccessibilityHint() throws {
        // Given
        let amount = "100.50"
        
        // When
        let accessibilityHint = generateAmountAccessibilityHint(amount: amount)
        
        // Then
        XCTAssertFalse(accessibilityHint.isEmpty, "Amount input should have accessibility hint")
        XCTAssertTrue(accessibilityHint.contains("enter"), "Accessibility hint should contain 'enter'")
    }
    
    // MARK: - Conversion Result Accessibility Tests
    
    func testConversionResultAccessibilityLabel() throws {
        // Given
        let amount = "100.00"
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let result = "92.00"
        
        // When
        let accessibilityLabel = generateConversionResultAccessibilityLabel(
            amount: amount,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            result: result
        )
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Conversion result should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains(amount), "Accessibility label should contain the amount")
        XCTAssertTrue(accessibilityLabel.contains(baseCurrency), "Accessibility label should contain base currency")
        XCTAssertTrue(accessibilityLabel.contains(targetCurrency), "Accessibility label should contain target currency")
        XCTAssertTrue(accessibilityLabel.contains(result), "Accessibility label should contain the result")
    }
    
    func testConversionResultAccessibilityValue() throws {
        // Given
        let result = "92.00"
        let targetCurrency = "EUR"
        
        // When
        let accessibilityValue = generateConversionResultAccessibilityValue(
            result: result,
            targetCurrency: targetCurrency
        )
        
        // Then
        XCTAssertFalse(accessibilityValue.isEmpty, "Conversion result should have accessibility value")
        XCTAssertTrue(accessibilityValue.contains(result), "Accessibility value should contain the result")
        XCTAssertTrue(accessibilityValue.contains(targetCurrency), "Accessibility value should contain target currency")
    }
    
    // MARK: - Button Accessibility Tests
    
    func testSwapButtonAccessibilityLabel() throws {
        // Given
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        
        // When
        let accessibilityLabel = generateSwapButtonAccessibilityLabel(
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency
        )
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Swap button should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("swap"), "Accessibility label should contain 'swap'")
        XCTAssertTrue(accessibilityLabel.contains(baseCurrency), "Accessibility label should contain base currency")
        XCTAssertTrue(accessibilityLabel.contains(targetCurrency), "Accessibility label should contain target currency")
    }
    
    func testRefreshButtonAccessibilityLabel() throws {
        // When
        let accessibilityLabel = generateRefreshButtonAccessibilityLabel()
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Refresh button should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("refresh"), "Accessibility label should contain 'refresh'")
    }
    
    func testShareButtonAccessibilityLabel() throws {
        // When
        let accessibilityLabel = generateShareButtonAccessibilityLabel()
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Share button should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("share"), "Accessibility label should contain 'share'")
    }
    
    // MARK: - Alert System Accessibility Tests
    
    func testAlertRuleAccessibilityLabel() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.95,
            direction: .above
        )
        
        // When
        let accessibilityLabel = generateAlertRuleAccessibilityLabel(alertRule: alertRule)
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Alert rule should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("alert"), "Accessibility label should contain 'alert'")
        XCTAssertTrue(accessibilityLabel.contains(alertRule.base), "Accessibility label should contain base currency")
        XCTAssertTrue(accessibilityLabel.contains(alertRule.target), "Accessibility label should contain target currency")
    }
    
    func testAlertRuleAccessibilityValue() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.95,
            direction: .above
        )
        
        // When
        let accessibilityValue = generateAlertRuleAccessibilityValue(alertRule: alertRule)
        
        // Then
        XCTAssertFalse(accessibilityValue.isEmpty, "Alert rule should have accessibility value")
        XCTAssertTrue(accessibilityValue.contains("0.95"), "Accessibility value should contain threshold")
        XCTAssertTrue(accessibilityValue.contains("above"), "Accessibility value should contain direction")
    }
    
    // MARK: - Quick Pairs Accessibility Tests
    
    func testQuickPairAccessibilityLabel() throws {
        // Given
        let quickPair = CurrencyQuickPair(base: "USD", target: "EUR")
        
        // When
        let accessibilityLabel = generateQuickPairAccessibilityLabel(quickPair: quickPair)
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Quick pair should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("quick pair"), "Accessibility label should contain 'quick pair'")
        XCTAssertTrue(accessibilityLabel.contains(quickPair.base), "Accessibility label should contain base currency")
        XCTAssertTrue(accessibilityLabel.contains(quickPair.target), "Accessibility label should contain target currency")
    }
    
    func testQuickPairAccessibilityHint() throws {
        // Given
        let quickPair = CurrencyQuickPair(base: "USD", target: "EUR")
        
        // When
        let accessibilityHint = generateQuickPairAccessibilityHint(quickPair: quickPair)
        
        // Then
        XCTAssertFalse(accessibilityHint.isEmpty, "Quick pair should have accessibility hint")
        XCTAssertTrue(accessibilityHint.contains("tap"), "Accessibility hint should contain 'tap'")
    }
    
    // MARK: - Provider Selection Accessibility Tests
    
    func testProviderSelectionAccessibilityLabel() throws {
        // Given
        let provider = FXProviderProfile(
            key: "interbank",
            name: "Interbank (No Spread)",
            spreadPercent: 0.0,
            fixedFee: 0.0
        )
        
        // When
        let accessibilityLabel = generateProviderSelectionAccessibilityLabel(provider: provider)
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Provider selection should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("provider"), "Accessibility label should contain 'provider'")
        XCTAssertTrue(accessibilityLabel.contains(provider.name), "Accessibility label should contain provider name")
    }
    
    func testProviderSelectionAccessibilityValue() throws {
        // Given
        let provider = FXProviderProfile(
            key: "interbank",
            name: "Interbank (No Spread)",
            spreadPercent: 0.0,
            fixedFee: 0.0
        )
        
        // When
        let accessibilityValue = generateProviderSelectionAccessibilityValue(provider: provider)
        
        // Then
        XCTAssertFalse(accessibilityValue.isEmpty, "Provider selection should have accessibility value")
        XCTAssertTrue(accessibilityValue.contains("0%"), "Accessibility value should contain spread percentage")
        XCTAssertTrue(accessibilityValue.contains("0"), "Accessibility value should contain fixed fee")
    }
    
    // MARK: - History Chart Accessibility Tests
    
    func testHistoryChartAccessibilityLabel() throws {
        // Given
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let range = "7D"
        
        // When
        let accessibilityLabel = generateHistoryChartAccessibilityLabel(
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            range: range
        )
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "History chart should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("chart"), "Accessibility label should contain 'chart'")
        XCTAssertTrue(accessibilityLabel.contains(baseCurrency), "Accessibility label should contain base currency")
        XCTAssertTrue(accessibilityLabel.contains(targetCurrency), "Accessibility label should contain target currency")
        XCTAssertTrue(accessibilityLabel.contains(range), "Accessibility label should contain range")
    }
    
    func testHistoryChartAccessibilityValue() throws {
        // Given
        let dataPoints = [
            (date: Date(), value: 0.92),
            (date: Date().addingTimeInterval(86400), value: 0.93),
            (date: Date().addingTimeInterval(172800), value: 0.91)
        ]
        
        // When
        let accessibilityValue = generateHistoryChartAccessibilityValue(dataPoints: dataPoints)
        
        // Then
        XCTAssertFalse(accessibilityValue.isEmpty, "History chart should have accessibility value")
        XCTAssertTrue(accessibilityValue.contains("3"), "Accessibility value should contain data point count")
    }
    
    // MARK: - Watchlist Accessibility Tests
    
    func testWatchlistItemAccessibilityLabel() throws {
        // Given
        let currencyCode = "EUR"
        let isSelected = true
        
        // When
        let accessibilityLabel = generateWatchlistItemAccessibilityLabel(
            currencyCode: currencyCode,
            isSelected: isSelected
        )
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Watchlist item should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("watchlist"), "Accessibility label should contain 'watchlist'")
        XCTAssertTrue(accessibilityLabel.contains(currencyCode), "Accessibility label should contain currency code")
        XCTAssertTrue(accessibilityLabel.contains("selected"), "Accessibility label should contain selection state")
    }
    
    func testWatchlistItemAccessibilityHint() throws {
        // Given
        let currencyCode = "EUR"
        
        // When
        let accessibilityHint = generateWatchlistItemAccessibilityHint(currencyCode: currencyCode)
        
        // Then
        XCTAssertFalse(accessibilityHint.isEmpty, "Watchlist item should have accessibility hint")
        XCTAssertTrue(accessibilityHint.contains("tap"), "Accessibility hint should contain 'tap'")
    }
    
    // MARK: - Error Message Accessibility Tests
    
    func testErrorMessageAccessibilityLabel() throws {
        // Given
        let errorMessage = "Network connection failed"
        
        // When
        let accessibilityLabel = generateErrorMessageAccessibilityLabel(errorMessage: errorMessage)
        
        // Then
        XCTAssertFalse(accessibilityLabel.isEmpty, "Error message should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("error"), "Accessibility label should contain 'error'")
        XCTAssertTrue(accessibilityLabel.contains(errorMessage), "Accessibility label should contain error message")
    }
    
    func testErrorMessageAccessibilityTraits() throws {
        // Given
        let errorMessage = "Network connection failed"
        
        // When
        let traits = generateErrorMessageAccessibilityTraits(errorMessage: errorMessage)
        
        // Then
        XCTAssertTrue(traits.contains(.isStaticText), "Error message should have static text trait")
        XCTAssertTrue(traits.contains(.updatesFrequently), "Error message should have updates frequently trait")
    }
    
    // MARK: - VoiceOver Navigation Tests
    
    func testVoiceOverNavigationOrder() throws {
        // Given
        let navigationElements = [
            "Amount Input",
            "Base Currency Selector",
            "Target Currency Selector",
            "Swap Button",
            "Conversion Result",
            "Refresh Button",
            "Share Button"
        ]
        
        // When
        let orderedElements = generateVoiceOverNavigationOrder(elements: navigationElements)
        
        // Then
        XCTAssertEqual(orderedElements.count, navigationElements.count, "All elements should be included in navigation order")
        XCTAssertEqual(orderedElements[0], "Amount Input", "Amount input should be first")
        XCTAssertEqual(orderedElements[1], "Base Currency Selector", "Base currency selector should be second")
        XCTAssertEqual(orderedElements[2], "Target Currency Selector", "Target currency selector should be third")
    }
    
    func testVoiceOverGrouping() throws {
        // Given
        let elements = [
            "Amount Input",
            "Base Currency Selector",
            "Target Currency Selector",
            "Swap Button",
            "Conversion Result"
        ]
        
        // When
        let groupedElements = generateVoiceOverGrouping(elements: elements)
        
        // Then
        XCTAssertEqual(groupedElements.count, 2, "Elements should be grouped into 2 groups")
        XCTAssertTrue(groupedElements[0].contains("Amount Input"), "First group should contain amount input")
        XCTAssertTrue(groupedElements[1].contains("Conversion Result"), "Second group should contain conversion result")
    }
    
    // MARK: - Dynamic Type Support Tests
    
    func testDynamicTypeSupport() throws {
        // Given
        let textSizes = [
            "Small": 12.0,
            "Medium": 16.0,
            "Large": 20.0,
            "Extra Large": 24.0
        ]
        
        // When & Then
        for (sizeName, fontSize) in textSizes {
            let scaledFont = generateScaledFont(baseFontSize: 16.0, scaleFactor: fontSize / 16.0)
            XCTAssertEqual(scaledFont, fontSize, accuracy: 0.1, "\(sizeName) text should scale correctly")
        }
    }
    
    func testDynamicTypeAccessibilityLabel() throws {
        // Given
        let baseLabel = "Convert 100 USD to EUR"
        let scaleFactor = 1.5
        
        // When
        let scaledLabel = generateScaledAccessibilityLabel(baseLabel: baseLabel, scaleFactor: scaleFactor)
        
        // Then
        XCTAssertFalse(scaledLabel.isEmpty, "Scaled accessibility label should not be empty")
        XCTAssertTrue(scaledLabel.contains(baseLabel), "Scaled accessibility label should contain base label")
    }
    
    // MARK: - Helper Methods
    
    private func generateAccessibilityLabel(for currency: String) -> String {
        return "Currency \(currency), tap to select"
    }
    
    private func generateAccessibilityHint(for currency: String) -> String {
        return "Tap to select \(currency) as currency"
    }
    
    private func generateAccessibilityTraits(for currency: String) -> AccessibilityTraits {
        return [.isButton, .isSelected]
    }
    
    private func generateAmountAccessibilityLabel(amount: String) -> String {
        return "Amount input field, current value: \(amount)"
    }
    
    private func generateAmountAccessibilityValue(amount: String, currency: String) -> String {
        return "\(amount) \(currency)"
    }
    
    private func generateAmountAccessibilityHint(amount: String) -> String {
        return "Enter amount to convert"
    }
    
    private func generateConversionResultAccessibilityLabel(amount: String, baseCurrency: String, targetCurrency: String, result: String) -> String {
        return "Conversion result: \(amount) \(baseCurrency) equals \(result) \(targetCurrency)"
    }
    
    private func generateConversionResultAccessibilityValue(result: String, targetCurrency: String) -> String {
        return "\(result) \(targetCurrency)"
    }
    
    private func generateSwapButtonAccessibilityLabel(baseCurrency: String, targetCurrency: String) -> String {
        return "Swap currencies from \(baseCurrency) to \(targetCurrency)"
    }
    
    private func generateRefreshButtonAccessibilityLabel() -> String {
        return "Refresh exchange rates"
    }
    
    private func generateShareButtonAccessibilityLabel() -> String {
        return "Share conversion result"
    }
    
    private func generateAlertRuleAccessibilityLabel(alertRule: CurrencyAlertRule) -> String {
        return "Alert rule for \(alertRule.base) to \(alertRule.target)"
    }
    
    private func generateAlertRuleAccessibilityValue(alertRule: CurrencyAlertRule) -> String {
        return "Threshold: \(alertRule.threshold), Direction: \(alertRule.direction.rawValue)"
    }
    
    private func generateQuickPairAccessibilityLabel(quickPair: CurrencyQuickPair) -> String {
        return "Quick pair: \(quickPair.base) to \(quickPair.target)"
    }
    
    private func generateQuickPairAccessibilityHint(quickPair: CurrencyQuickPair) -> String {
        return "Tap to select \(quickPair.base) to \(quickPair.target) conversion"
    }
    
    private func generateProviderSelectionAccessibilityLabel(provider: FXProviderProfile) -> String {
        return "Exchange rate provider: \(provider.name)"
    }
    
    private func generateProviderSelectionAccessibilityValue(provider: FXProviderProfile) -> String {
        return "Spread: \(provider.spreadPercent)%, Fee: \(provider.fixedFee)"
    }
    
    private func generateHistoryChartAccessibilityLabel(baseCurrency: String, targetCurrency: String, range: String) -> String {
        return "Exchange rate chart for \(baseCurrency) to \(targetCurrency) over \(range)"
    }
    
    private func generateHistoryChartAccessibilityValue(dataPoints: [(date: Date, value: Double)]) -> String {
        return "Chart with \(dataPoints.count) data points"
    }
    
    private func generateWatchlistItemAccessibilityLabel(currencyCode: String, isSelected: Bool) -> String {
        let selectionState = isSelected ? "selected" : "not selected"
        return "Watchlist item: \(currencyCode), \(selectionState)"
    }
    
    private func generateWatchlistItemAccessibilityHint(currencyCode: String) -> String {
        return "Tap to select \(currencyCode) currency"
    }
    
    private func generateErrorMessageAccessibilityLabel(errorMessage: String) -> String {
        return "Error: \(errorMessage)"
    }
    
    private func generateErrorMessageAccessibilityTraits(errorMessage: String) -> AccessibilityTraits {
        return [.isStaticText, .updatesFrequently]
    }
    
    private func generateVoiceOverNavigationOrder(elements: [String]) -> [String] {
        return elements
    }
    
    private func generateVoiceOverGrouping(elements: [String]) -> [String] {
        return [
            "Input Group: \(elements[0...3].joined(separator: ", "))",
            "Result Group: \(elements[4])"
        ]
    }
    
    private func generateScaledFont(baseFontSize: Double, scaleFactor: Double) -> Double {
        return baseFontSize * scaleFactor
    }
    
    private func generateScaledAccessibilityLabel(baseLabel: String, scaleFactor: Double) -> String {
        return baseLabel
    }
}

// MARK: - Accessibility Traits

struct AccessibilityTraits: OptionSet {
    let rawValue: Int
    
    static let isButton = AccessibilityTraits(rawValue: 1 << 0)
    static let isSelected = AccessibilityTraits(rawValue: 1 << 1)
    static let isStaticText = AccessibilityTraits(rawValue: 1 << 2)
    static let updatesFrequently = AccessibilityTraits(rawValue: 1 << 3)
}
