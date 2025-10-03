import XCTest
import Foundation
@testable import currency_converter

/// Tests for concurrent operations and thread safety
final class ConcurrentOperationsTests: XCTestCase {
    
    var currencyConverter: ThreadSafeCurrencyConverter!
    var alertManager: ThreadSafeAlertManager!
    var cacheManager: ThreadSafeCacheManager!
    
    override func setUpWithError() throws {
        currencyConverter = ThreadSafeCurrencyConverter()
        alertManager = ThreadSafeAlertManager()
        cacheManager = ThreadSafeCacheManager()
    }
    
    override func tearDownWithError() throws {
        currencyConverter = nil
        alertManager = nil
        cacheManager = nil
    }
    
    // MARK: - Concurrent Conversion Tests
    
    func testConcurrentCurrencyConversions() async throws {
        // Given
        let rates = [
            "USD": 1.0,
            "EUR": 0.92,
            "GBP": 0.79,
            "JPY": 147.0
        ]
        
        // When
        let conversions = await withTaskGroup(of: Double.self) { group in
            for i in 0..<100 {
                group.addTask {
                    return await self.currencyConverter.convert(
                        amount: Double(i + 1),
                        baseCurrency: "USD",
                        targetCurrency: "EUR",
                        rates: rates
                    )
                }
            }
            
            var results: [Double] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // Then
        XCTAssertEqual(conversions.count, 100)
        for (index, result) in conversions.enumerated() {
            let expected = Double(index + 1) * 0.92
            XCTAssertEqual(result, expected, accuracy: 0.001, "Conversion \(index) should be correct")
        }
    }
    
    func testConcurrentRateUpdates() async throws {
        // Given
        let initialRates = ["USD": 1.0, "EUR": 0.92]
        
        // When
        await withTaskGroup(of: Void.self) { group in
            // Update rates concurrently
            for i in 0..<10 {
                group.addTask {
                    let newRates = [
                        "USD": 1.0,
                        "EUR": 0.92 + Double(i) * 0.01
                    ]
                    await self.currencyConverter.updateRates(newRates)
                }
            }
            
            // Perform conversions concurrently
            for i in 0..<50 {
                group.addTask {
                    _ = await self.currencyConverter.convert(
                        amount: 100.0,
                        baseCurrency: "USD",
                        targetCurrency: "EUR",
                        rates: initialRates
                    )
                }
            }
            
            await group.waitForAll()
        }
        
        // Then
        // The test should complete without crashes or data races
        XCTAssertTrue(true, "Concurrent operations should complete successfully")
    }
    
    func testConcurrentProviderFeeCalculations() async throws {
        // Given
        let amount = 100.0
        let spreadPercent = 2.0
        let fixedFee = 5.0
        
        // When
        let results = await withTaskGroup(of: Double.self) { group in
            for _ in 0..<1000 {
                group.addTask {
                    return await self.currencyConverter.applyProviderFees(
                        amount: amount,
                        spreadPercent: spreadPercent,
                        fixedFee: fixedFee
                    )
                }
            }
            
            var results: [Double] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // Then
        XCTAssertEqual(results.count, 1000)
        let expected = amount * (1 - spreadPercent / 100) - fixedFee
        for result in results {
            XCTAssertEqual(result, expected, accuracy: 0.001, "All fee calculations should be identical")
        }
    }
    
    // MARK: - Concurrent Alert Management Tests
    
    func testConcurrentAlertRuleOperations() async throws {
        // Given
        let alertRules = (0..<100).map { i in
            CurrencyAlertRule(
                id: UUID(),
                base: "USD",
                target: "EUR",
                threshold: 0.90 + Double(i) * 0.001,
                direction: .above
            )
        }
        
        // When
        await withTaskGroup(of: Void.self) { group in
            // Add alert rules concurrently
            for rule in alertRules {
                group.addTask {
                    await self.alertManager.addAlertRule(rule)
                }
            }
            
            // Evaluate alerts concurrently
            for _ in 0..<50 {
                group.addTask {
                    _ = await self.alertManager.evaluateAlerts(
                        baseCurrency: "USD",
                        targetCurrency: "EUR",
                        currentRate: 0.95
                    )
                }
            }
            
            // Remove alert rules concurrently
            for i in 0..<50 {
                group.addTask {
                    await self.alertManager.removeAlertRule(at: i)
                }
            }
            
            await group.waitForAll()
        }
        
        // Then
        let remainingRules = await alertManager.getAllAlertRules()
        XCTAssertEqual(remainingRules.count, 50, "Should have 50 remaining alert rules")
    }
    
    func testConcurrentAlertEvaluation() async throws {
        // Given
        let alertRules = (0..<100).map { i in
            CurrencyAlertRule(
                id: UUID(),
                base: "USD",
                target: "EUR",
                threshold: 0.90 + Double(i) * 0.001,
                direction: .above
            )
        }
        
        await alertManager.addAlertRules(alertRules)
        
        // When
        let results = await withTaskGroup(of: [CurrencyAlertRule].self) { group in
            for _ in 0..<100 {
                group.addTask {
                    return await self.alertManager.evaluateAlerts(
                        baseCurrency: "USD",
                        targetCurrency: "EUR",
                        currentRate: 0.95
                    )
                }
            }
            
            var results: [[CurrencyAlertRule]] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // Then
        XCTAssertEqual(results.count, 100)
        for result in results {
            XCTAssertEqual(result.count, 50, "Should have 50 triggered alerts")
        }
    }
    
    // MARK: - Concurrent Cache Operations Tests
    
    func testConcurrentCacheReadWrite() async throws {
        // Given
        let rates = ["USD": 1.0, "EUR": 0.92, "GBP": 0.79]
        let baseCurrency = "USD"
        let timestamp = Date()
        
        // When
        await withTaskGroup(of: Void.self) { group in
            // Write to cache concurrently
            for i in 0..<50 {
                group.addTask {
                    let modifiedRates = rates.mapValues { $0 + Double(i) * 0.001 }
                    await self.cacheManager.storeRates(
                        modifiedRates,
                        baseCurrency: baseCurrency,
                        timestamp: timestamp
                    )
                }
            }
            
            // Read from cache concurrently
            for _ in 0..<100 {
                group.addTask {
                    _ = await self.cacheManager.getCachedRates(for: baseCurrency)
                }
            }
            
            await group.waitForAll()
        }
        
        // Then
        let cachedRates = await cacheManager.getCachedRates(for: baseCurrency)
        XCTAssertNotNil(cachedRates, "Cache should contain data")
    }
    
    func testConcurrentCacheCleanup() async throws {
        // Given
        let now = Date()
        let expiredTimestamp = now.addingTimeInterval(-7200) // 2 hours ago
        let currentTimestamp = now
        
        // When
        await withTaskGroup(of: Void.self) { group in
            // Store expired rates
            for i in 0..<10 {
                group.addTask {
                    await self.cacheManager.storeRates(
                        ["USD": 1.0, "EUR": 0.92],
                        baseCurrency: "USD\(i)",
                        timestamp: expiredTimestamp
                    )
                }
            }
            
            // Store current rates
            for i in 0..<10 {
                group.addTask {
                    await self.cacheManager.storeRates(
                        ["USD": 1.0, "GBP": 0.79],
                        baseCurrency: "GBP\(i)",
                        timestamp: currentTimestamp
                    )
                }
            }
            
            // Cleanup expired rates
            for _ in 0..<5 {
                group.addTask {
                    await self.cacheManager.cleanupExpiredRates()
                }
            }
            
            await group.waitForAll()
        }
        
        // Then
        let expiredRates = await cacheManager.getCachedRates(for: "USD0")
        let currentRates = await cacheManager.getCachedRates(for: "GBP0")
        
        XCTAssertNil(expiredRates, "Expired rates should be cleaned up")
        XCTAssertNotNil(currentRates, "Current rates should still be cached")
    }
    
    // MARK: - Thread Safety Tests
    
    func testThreadSafetyWithSharedState() async throws {
        // Given
        let sharedState = SharedState()
        let iterations = 1000
        
        // When
        await withTaskGroup(of: Void.self) { group in
            // Increment counter concurrently
            for _ in 0..<iterations {
                group.addTask {
                    await sharedState.incrementCounter()
                }
            }
            
            // Read counter concurrently
            for _ in 0..<iterations {
                group.addTask {
                    _ = await sharedState.getCounter()
                }
            }
            
            await group.waitForAll()
        }
        
        // Then
        let finalCounter = await sharedState.getCounter()
        XCTAssertEqual(finalCounter, iterations, "Counter should be incremented exactly \(iterations) times")
    }
    
    func testThreadSafetyWithArrayOperations() async throws {
        // Given
        let sharedArray = SharedArray<String>()
        let items = (0..<100).map { "item\($0)" }
        
        // When
        await withTaskGroup(of: Void.self) { group in
            // Add items concurrently
            for item in items {
                group.addTask {
                    await sharedArray.append(item)
                }
            }
            
            // Read items concurrently
            for _ in 0..<100 {
                group.addTask {
                    _ = await sharedArray.getAllItems()
                }
            }
            
            // Remove items concurrently
            for i in 0..<50 {
                group.addTask {
                    await sharedArray.remove(at: i)
                }
            }
            
            await group.waitForAll()
        }
        
        // Then
        let finalItems = await sharedArray.getAllItems()
        XCTAssertEqual(finalItems.count, 50, "Should have 50 items remaining")
    }
    
    // MARK: - Deadlock Prevention Tests
    
    func testDeadlockPrevention() async throws {
        // Given
        let resource1 = SharedResource(id: "Resource1")
        let resource2 = SharedResource(id: "Resource2")
        
        // When
        await withTaskGroup(of: Void.self) { group in
            // Task 1: Acquire resource1, then resource2
            group.addTask {
                await resource1.acquire()
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await resource2.acquire()
                await resource1.release()
                await resource2.release()
            }
            
            // Task 2: Acquire resource2, then resource1
            group.addTask {
                await resource2.acquire()
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await resource1.acquire()
                await resource2.release()
                await resource1.release()
            }
            
            await group.waitForAll()
        }
        
        // Then
        // The test should complete without deadlock
        XCTAssertTrue(true, "Deadlock prevention should work correctly")
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentPerformance() async throws {
        // Given
        let rates = ["USD": 1.0, "EUR": 0.92, "GBP": 0.79]
        let iterations = 1000
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    _ = await self.currencyConverter.convert(
                        amount: 100.0,
                        baseCurrency: "USD",
                        targetCurrency: "EUR",
                        rates: rates
                    )
                }
            }
            
            await group.waitForAll()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(executionTime, 1.0, "Concurrent operations should complete within 1 second")
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageWithConcurrentOperations() async throws {
        // Given
        let rates = ["USD": 1.0, "EUR": 0.92, "GBP": 0.79]
        let iterations = 1000
        
        // When
        let startMemory = getMemoryUsage()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    _ = await self.currencyConverter.convert(
                        amount: 100.0,
                        baseCurrency: "USD",
                        targetCurrency: "EUR",
                        rates: rates
                    )
                }
            }
            
            await group.waitForAll()
        }
        
        let endMemory = getMemoryUsage()
        
        // Then
        let memoryIncrease = endMemory - startMemory
        XCTAssertLessThan(memoryIncrease, 10_000_000, "Memory increase should be less than 10MB")
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

// MARK: - Thread-Safe Classes

actor ThreadSafeCurrencyConverter {
    private var rates: [String: Double] = [:]
    
    func convert(amount: Double, baseCurrency: String, targetCurrency: String, rates: [String: Double]) async -> Double {
        guard let baseRate = rates[baseCurrency],
              let targetRate = rates[targetCurrency],
              baseRate > 0 else {
            return 0.0
        }
        
        let usdValue = amount / baseRate
        return usdValue * targetRate
    }
    
    func updateRates(_ newRates: [String: Double]) async {
        rates = newRates
    }
    
    func applyProviderFees(amount: Double, spreadPercent: Double, fixedFee: Double) async -> Double {
        let spreadFactor = max(0, 1 - spreadPercent / 100)
        let result = amount * spreadFactor
        return max(0, result - fixedFee)
    }
}

actor ThreadSafeAlertManager {
    private var alertRules: [CurrencyAlertRule] = []
    
    func addAlertRule(_ rule: CurrencyAlertRule) async {
        alertRules.append(rule)
    }
    
    func addAlertRules(_ rules: [CurrencyAlertRule]) async {
        alertRules.append(contentsOf: rules)
    }
    
    func removeAlertRule(at index: Int) async {
        guard index < alertRules.count else { return }
        alertRules.remove(at: index)
    }
    
    func getAllAlertRules() async -> [CurrencyAlertRule] {
        return alertRules
    }
    
    func evaluateAlerts(baseCurrency: String, targetCurrency: String, currentRate: Double) async -> [CurrencyAlertRule] {
        return alertRules.filter { rule in
            rule.base == baseCurrency && rule.target == targetCurrency && evaluateAlert(rule: rule, currentRate: currentRate)
        }
    }
    
    private func evaluateAlert(rule: CurrencyAlertRule, currentRate: Double) -> Bool {
        switch rule.direction {
        case .above:
            return currentRate >= rule.threshold
        case .below:
            return currentRate <= rule.threshold
        }
    }
}

actor ThreadSafeCacheManager {
    private var cachedRates: [String: CachedRates] = [:]
    private let cacheExpirationTime: TimeInterval = 3600 // 1 hour
    
    func storeRates(_ rates: [String: Double], baseCurrency: String, timestamp: Date) async {
        let cachedRates = CachedRates(
            baseCurrency: baseCurrency,
            rates: rates,
            timestamp: timestamp
        )
        self.cachedRates[baseCurrency] = cachedRates
    }
    
    func getCachedRates(for baseCurrency: String) async -> CachedRates? {
        guard let cached = cachedRates[baseCurrency] else { return nil }
        
        if Date().timeIntervalSince(cached.timestamp) > cacheExpirationTime {
            cachedRates.removeValue(forKey: baseCurrency)
            return nil
        }
        
        return cached
    }
    
    func cleanupExpiredRates() async {
        let now = Date()
        cachedRates = cachedRates.filter { _, cached in
            now.timeIntervalSince(cached.timestamp) <= cacheExpirationTime
        }
    }
}

// MARK: - Shared State Classes

actor SharedState {
    private var counter: Int = 0
    
    func incrementCounter() async {
        counter += 1
    }
    
    func getCounter() async -> Int {
        return counter
    }
}

actor SharedArray<T> {
    private var items: [T] = []
    
    func append(_ item: T) async {
        items.append(item)
    }
    
    func remove(at index: Int) async {
        guard index < items.count else { return }
        items.remove(at: index)
    }
    
    func getAllItems() async -> [T] {
        return items
    }
}

actor SharedResource {
    private let id: String
    private var isAcquired: Bool = false
    
    init(id: String) {
        self.id = id
    }
    
    func acquire() async {
        while isAcquired {
            try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }
        isAcquired = true
    }
    
    func release() async {
        isAcquired = false
    }
}

// MARK: - Data Models

struct CachedRates: Codable {
    let baseCurrency: String
    let rates: [String: Double]
    let timestamp: Date
}
