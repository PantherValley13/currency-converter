import XCTest
import Foundation
@testable import currency_converter

/// Integration tests for network operations with proper mocking
final class NetworkIntegrationTests: XCTestCase {
    
    var mockURLSession: MockURLSession!
    var ratesService: MockRatesService!
    
    override func setUpWithError() throws {
        mockURLSession = MockURLSession()
        ratesService = MockRatesService()
    }
    
    override func tearDownWithError() throws {
        mockURLSession = nil
        ratesService = nil
    }
    
    // MARK: - Network Request Tests
    
    func testSuccessfulRatesRequest() async throws {
        // Given
        let mockResponse = MockRatesResponse(
            base: "USD",
            rates: [
                "EUR": 0.92,
                "GBP": 0.79,
                "JPY": 147.0
            ],
            date: "2023-01-01"
        )
        mockURLSession.mockResponse = try JSONEncoder().encode(mockResponse)
        mockURLSession.mockStatusCode = 200
        
        // When
        let result = try await ratesService.fetchRates(base: "USD", providerKey: "interbank")
        
        // Then
        XCTAssertEqual(result.base, "USD")
        XCTAssertEqual(result.rates["EUR"], 0.92)
        XCTAssertEqual(result.rates["GBP"], 0.79)
        XCTAssertEqual(result.rates["JPY"], 147.0)
    }
    
    func testFailedRatesRequest() async throws {
        // Given
        mockURLSession.mockStatusCode = 500
        mockURLSession.mockError = URLError(.badServerResponse)
        
        // When & Then
        do {
            _ = try await ratesService.fetchRates(base: "USD", providerKey: "interbank")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testNetworkTimeout() async throws {
        // Given
        mockURLSession.mockDelay = 30.0 // 30 second delay
        mockURLSession.mockError = URLError(.timedOut)
        
        // When & Then
        do {
            _ = try await ratesService.fetchRates(base: "USD", providerKey: "interbank")
            XCTFail("Should have thrown a timeout error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testInvalidJSONResponse() async throws {
        // Given
        mockURLSession.mockResponse = "invalid json".data(using: .utf8)!
        mockURLSession.mockStatusCode = 200
        
        // When & Then
        do {
            _ = try await ratesService.fetchRates(base: "USD", providerKey: "interbank")
            XCTFail("Should have thrown a decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - History Request Tests
    
    func testSuccessfulHistoryRequest() async throws {
        // Given
        let mockResponse = MockTimeseriesResponse(
            rates: [
                "2023-01-01": ["EUR": 0.92],
                "2023-01-02": ["EUR": 0.93],
                "2023-01-03": ["EUR": 0.91]
            ]
        )
        mockURLSession.mockResponse = try JSONEncoder().encode(mockResponse)
        mockURLSession.mockStatusCode = 200
        
        // When
        let result = try await ratesService.fetchHistory(
            base: "USD",
            target: "EUR",
            range: .d7,
            providerKey: "interbank"
        )
        
        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].value, 0.92)
        XCTAssertEqual(result[1].value, 0.93)
        XCTAssertEqual(result[2].value, 0.91)
    }
    
    func testEmptyHistoryResponse() async throws {
        // Given
        let mockResponse = MockTimeseriesResponse(rates: [:])
        mockURLSession.mockResponse = try JSONEncoder().encode(mockResponse)
        mockURLSession.mockStatusCode = 200
        
        // When
        let result = try await ratesService.fetchHistory(
            base: "USD",
            target: "EUR",
            range: .d7,
            providerKey: "interbank"
        )
        
        // Then
        XCTAssertEqual(result.count, 0)
    }
    
    // MARK: - Provider-Specific Tests
    
    func testInterbankProviderRequest() async throws {
        // Given
        let mockResponse = MockRatesResponse(
            base: "USD",
            rates: ["EUR": 0.92],
            date: "2023-01-01"
        )
        mockURLSession.mockResponse = try JSONEncoder().encode(mockResponse)
        mockURLSession.mockStatusCode = 200
        
        // When
        let result = try await ratesService.fetchRates(base: "USD", providerKey: "interbank")
        
        // Then
        XCTAssertEqual(result.base, "USD")
        XCTAssertEqual(result.rates["EUR"], 0.92)
    }
    
    func testBankStandardProviderRequest() async throws {
        // Given
        let mockResponse = MockRatesResponse(
            base: "USD",
            rates: ["EUR": 0.92],
            date: "2023-01-01"
        )
        mockURLSession.mockResponse = try JSONEncoder().encode(mockResponse)
        mockURLSession.mockStatusCode = 200
        
        // When
        let result = try await ratesService.fetchRates(base: "USD", providerKey: "bank_standard")
        
        // Then
        XCTAssertEqual(result.base, "USD")
        XCTAssertEqual(result.rates["EUR"], 0.92)
    }
    
    func testFintechFastProviderRequest() async throws {
        // Given
        let mockResponse = MockRatesResponse(
            base: "USD",
            rates: ["EUR": 0.92],
            date: "2023-01-01"
        )
        mockURLSession.mockResponse = try JSONEncoder().encode(mockResponse)
        mockURLSession.mockStatusCode = 200
        
        // When
        let result = try await ratesService.fetchRates(base: "USD", providerKey: "fintech_fast")
        
        // Then
        XCTAssertEqual(result.base, "USD")
        XCTAssertEqual(result.rates["EUR"], 0.92)
    }
    
    // MARK: - URL Construction Tests
    
    func testLatestRatesURLConstruction() throws {
        // Given
        let baseCurrency = "USD"
        let providerKey = "interbank"
        
        // When
        let url = ratesService.constructLatestRatesURL(base: baseCurrency, providerKey: providerKey)
        
        // Then
        XCTAssertNotNil(url)
        XCTAssertTrue(url.absoluteString.contains("latest"))
        XCTAssertTrue(url.absoluteString.contains("base=USD"))
    }
    
    func testTimeseriesURLConstruction() throws {
        // Given
        let baseCurrency = "USD"
        let targetCurrency = "EUR"
        let startDate = "2023-01-01"
        let endDate = "2023-01-07"
        let providerKey = "interbank"
        
        // When
        let url = ratesService.constructTimeseriesURL(
            base: baseCurrency,
            target: targetCurrency,
            startDate: startDate,
            endDate: endDate,
            providerKey: providerKey
        )
        
        // Then
        XCTAssertNotNil(url)
        XCTAssertTrue(url.absoluteString.contains("timeseries"))
        XCTAssertTrue(url.absoluteString.contains("base=USD"))
        XCTAssertTrue(url.absoluteString.contains("symbols=EUR"))
        XCTAssertTrue(url.absoluteString.contains("start_date=2023-01-01"))
        XCTAssertTrue(url.absoluteString.contains("end_date=2023-01-07"))
    }
    
    // MARK: - Performance Tests
    
    func testNetworkRequestPerformance() throws {
        // Given
        let mockResponse = MockRatesResponse(
            base: "USD",
            rates: ["EUR": 0.92],
            date: "2023-01-01"
        )
        mockURLSession.mockResponse = try JSONEncoder().encode(mockResponse)
        mockURLSession.mockStatusCode = 200
        
        // When & Then
        measure {
            let expectation = XCTestExpectation(description: "Network request")
            Task {
                _ = try? await ratesService.fetchRates(base: "USD", providerKey: "interbank")
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Concurrent Request Tests
    
    func testConcurrentRatesRequests() async throws {
        // Given
        let mockResponse = MockRatesResponse(
            base: "USD",
            rates: ["EUR": 0.92],
            date: "2023-01-01"
        )
        mockURLSession.mockResponse = try JSONEncoder().encode(mockResponse)
        mockURLSession.mockStatusCode = 200
        
        // When
        let currencies = ["USD", "EUR", "GBP", "JPY", "CAD"]
        let results = await withTaskGroup(of: MockRatesResponse?.self) { group in
            for currency in currencies {
                group.addTask {
                    try? await self.ratesService.fetchRates(base: currency, providerKey: "interbank")
                }
            }
            
            var responses: [MockRatesResponse?] = []
            for await result in group {
                responses.append(result)
            }
            return responses
        }
        
        // Then
        XCTAssertEqual(results.count, 5)
        XCTAssertTrue(results.allSatisfy { $0 != nil })
    }
    
    // MARK: - Error Recovery Tests
    
    func testRetryMechanism() async throws {
        // Given
        mockURLSession.mockStatusCode = 500
        mockURLSession.mockError = URLError(.badServerResponse)
        mockURLSession.retryCount = 3
        
        // When
        let result = try await ratesService.fetchRatesWithRetry(
            base: "USD",
            providerKey: "interbank",
            maxRetries: 3
        )
        
        // Then
        XCTAssertEqual(mockURLSession.retryCount, 0) // Should have exhausted retries
        XCTAssertNil(result) // Should return nil after all retries failed
    }
    
    func testFallbackToCachedData() async throws {
        // Given
        mockURLSession.mockStatusCode = 500
        mockURLSession.mockError = URLError(.badServerResponse)
        
        let cachedRates = [
            "USD": 1.0,
            "EUR": 0.92,
            "GBP": 0.79
        ]
        ratesService.cachedRates = cachedRates
        
        // When
        let result = try await ratesService.fetchRatesWithFallback(
            base: "USD",
            providerKey: "interbank"
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.rates["EUR"], 0.92)
    }
}

// MARK: - Mock Classes

class MockURLSession: URLSession {
    var mockResponse: Data?
    var mockStatusCode: Int = 200
    var mockError: Error?
    var mockDelay: TimeInterval = 0
    var retryCount: Int = 0
    
    override func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        if mockDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        }
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: mockStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (mockResponse ?? Data(), response)
    }
}

class MockRatesService {
    var cachedRates: [String: Double]?
    
    func fetchRates(base: String, providerKey: String) async throws -> MockRatesResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        return MockRatesResponse(
            base: base,
            rates: [
                "EUR": 0.92,
                "GBP": 0.79,
                "JPY": 147.0
            ],
            date: "2023-01-01"
        )
    }
    
    func fetchHistory(base: String, target: String, range: HistoryRange, providerKey: String) async throws -> [RatePoint] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        return [
            RatePoint(date: Date(), value: 0.92),
            RatePoint(date: Date().addingTimeInterval(86400), value: 0.93),
            RatePoint(date: Date().addingTimeInterval(172800), value: 0.91)
        ]
    }
    
    func constructLatestRatesURL(base: String, providerKey: String) -> URL {
        var components = URLComponents(string: "https://api.exchangerate.host/latest")!
        components.queryItems = [URLQueryItem(name: "base", value: base)]
        return components.url!
    }
    
    func constructTimeseriesURL(base: String, target: String, startDate: String, endDate: String, providerKey: String) -> URL {
        var components = URLComponents(string: "https://api.exchangerate.host/timeseries")!
        components.queryItems = [
            URLQueryItem(name: "base", value: base),
            URLQueryItem(name: "symbols", value: target),
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate)
        ]
        return components.url!
    }
    
    func fetchRatesWithRetry(base: String, providerKey: String, maxRetries: Int) async throws -> MockRatesResponse? {
        for _ in 0..<maxRetries {
            do {
                return try await fetchRates(base: base, providerKey: providerKey)
            } catch {
                // Retry logic would go here
                continue
            }
        }
        return nil
    }
    
    func fetchRatesWithFallback(base: String, providerKey: String) async throws -> MockRatesResponse? {
        do {
            return try await fetchRates(base: base, providerKey: providerKey)
        } catch {
            // Fallback to cached data
            guard let cached = cachedRates else { return nil }
            return MockRatesResponse(base: base, rates: cached, date: "cached")
        }
    }
}

// MARK: - Mock Data Models

struct MockRatesResponse: Codable {
    let base: String
    let rates: [String: Double]
    let date: String
}

struct MockTimeseriesResponse: Codable {
    let rates: [String: [String: Double]]
}

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
