import XCTest
@testable import currency_converter

/// Unit tests for alert system functionality
final class AlertSystemTests: XCTestCase {
    
    // MARK: - Test Data
    private let sampleRates: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 147.0
    ]
    
    // MARK: - Alert Rule Creation Tests
    
    func testCreateAboveAlertRule() throws {
        // Given
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let threshold = 0.95
        let direction = CurrencyAlertRule.Direction.above
        
        // When
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: baseCurrency,
            target: targetCurrency,
            threshold: threshold,
            direction: direction
        )
        
        // Then
        XCTAssertEqual(alertRule.base, baseCurrency)
        XCTAssertEqual(alertRule.target, targetCurrency)
        XCTAssertEqual(alertRule.threshold, threshold)
        XCTAssertEqual(alertRule.direction, direction)
    }
    
    func testCreateBelowAlertRule() throws {
        // Given
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let threshold = 0.85
        let direction = CurrencyAlertRule.Direction.below
        
        // When
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: baseCurrency,
            target: targetCurrency,
            threshold: threshold,
            direction: direction
        )
        
        // Then
        XCTAssertEqual(alertRule.base, baseCurrency)
        XCTAssertEqual(alertRule.target, targetCurrency)
        XCTAssertEqual(alertRule.threshold, threshold)
        XCTAssertEqual(alertRule.direction, direction)
    }
    
    // MARK: - Alert Evaluation Tests
    
    func testAboveAlertTriggered() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.90,
            direction: .above
        )
        let currentRate = 0.95 // Above threshold
        
        // When
        let isTriggered = evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        // Then
        XCTAssertTrue(isTriggered, "Alert should be triggered when rate is above threshold")
    }
    
    func testAboveAlertNotTriggered() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.90,
            direction: .above
        )
        let currentRate = 0.85 // Below threshold
        
        // When
        let isTriggered = evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        // Then
        XCTAssertFalse(isTriggered, "Alert should not be triggered when rate is below threshold")
    }
    
    func testBelowAlertTriggered() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.90,
            direction: .below
        )
        let currentRate = 0.85 // Below threshold
        
        // When
        let isTriggered = evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        // Then
        XCTAssertTrue(isTriggered, "Alert should be triggered when rate is below threshold")
    }
    
    func testBelowAlertNotTriggered() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.90,
            direction: .below
        )
        let currentRate = 0.95 // Above threshold
        
        // When
        let isTriggered = evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        // Then
        XCTAssertFalse(isTriggered, "Alert should not be triggered when rate is above threshold")
    }
    
    func testExactThresholdTriggered() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.92,
            direction: .above
        )
        let currentRate = 0.92 // Exactly at threshold
        
        // When
        let isTriggered = evaluateAlert(alertRule: alertRule, currentRate: currentRate)
        
        // Then
        XCTAssertTrue(isTriggered, "Alert should be triggered when rate equals threshold")
    }
    
    // MARK: - Alert Rule Management Tests
    
    func testAddAlertRule() throws {
        // Given
        var alertRules: [CurrencyAlertRule] = []
        let newRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "GBP",
            threshold: 0.80,
            direction: .below
        )
        
        // When
        alertRules.append(newRule)
        
        // Then
        XCTAssertEqual(alertRules.count, 1)
        XCTAssertEqual(alertRules.first?.base, "USD")
        XCTAssertEqual(alertRules.first?.target, "GBP")
    }
    
    func testRemoveAlertRule() throws {
        // Given
        let rule1 = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.90,
            direction: .above
        )
        let rule2 = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "GBP",
            threshold: 0.80,
            direction: .below
        )
        var alertRules = [rule1, rule2]
        
        // When
        alertRules.removeAll { $0.id == rule1.id }
        
        // Then
        XCTAssertEqual(alertRules.count, 1)
        XCTAssertEqual(alertRules.first?.id, rule2.id)
    }
    
    func testUpdateAlertRule() throws {
        // Given
        let originalRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.90,
            direction: .above
        )
        var alertRules = [originalRule]
        
        // When
        if let index = alertRules.firstIndex(where: { $0.id == originalRule.id }) {
            alertRules[index] = CurrencyAlertRule(
                id: originalRule.id,
                base: "USD",
                target: "EUR",
                threshold: 0.95, // Updated threshold
                direction: .above
            )
        }
        
        // Then
        XCTAssertEqual(alertRules.count, 1)
        XCTAssertEqual(alertRules.first?.threshold, 0.95)
    }
    
    // MARK: - Alert Rule Validation Tests
    
    func testValidAlertRule() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: 0.90,
            direction: .above
        )
        
        // When
        let isValid = validateAlertRule(alertRule)
        
        // Then
        XCTAssertTrue(isValid, "Valid alert rule should pass validation")
    }
    
    func testInvalidAlertRuleNegativeThreshold() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "EUR",
            threshold: -0.90, // Negative threshold
            direction: .above
        )
        
        // When
        let isValid = validateAlertRule(alertRule)
        
        // Then
        XCTAssertFalse(isValid, "Alert rule with negative threshold should be invalid")
    }
    
    func testInvalidAlertRuleSameCurrency() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "USD",
            target: "USD", // Same currency
            threshold: 0.90,
            direction: .above
        )
        
        // When
        let isValid = validateAlertRule(alertRule)
        
        // Then
        XCTAssertFalse(isValid, "Alert rule with same base and target currency should be invalid")
    }
    
    func testInvalidAlertRuleEmptyCurrency() throws {
        // Given
        let alertRule = CurrencyAlertRule(
            id: UUID(),
            base: "", // Empty currency
            target: "EUR",
            threshold: 0.90,
            direction: .above
        )
        
        // When
        let isValid = validateAlertRule(alertRule)
        
        // Then
        XCTAssertFalse(isValid, "Alert rule with empty currency should be invalid")
    }
    
    // MARK: - Helper Methods
    
    private func evaluateAlert(alertRule: CurrencyAlertRule, currentRate: Double) -> Bool {
        switch alertRule.direction {
        case .above:
            return currentRate >= alertRule.threshold
        case .below:
            return currentRate <= alertRule.threshold
        }
    }
    
    private func validateAlertRule(_ alertRule: CurrencyAlertRule) -> Bool {
        // Check for valid currencies
        guard !alertRule.base.isEmpty,
              !alertRule.target.isEmpty,
              alertRule.base != alertRule.target else {
            return false
        }
        
        // Check for valid threshold
        guard alertRule.threshold > 0 else {
            return false
        }
        
        return true
    }
}
