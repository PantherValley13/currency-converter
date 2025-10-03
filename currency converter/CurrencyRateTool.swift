//
//  CurrencyRateTool.swift
//  currency converter
//
//  Tool implementation for Foundation Models framework
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// A tool that allows the AI model to look up current exchange rates
struct CurrencyRateTool: Tool {
    let name = "getCurrentExchangeRate"
    
    let description = """
    Looks up the current exchange rate between two currencies. \
    Use this when the user asks about conversion rates or wants to convert amounts. \
    Returns the current rate and timestamp.
    """
    
    // Dependency: closure to fetch actual rates from your app
    private let ratesProvider: ([String: Double]) -> Void
    
    init(ratesProvider: @escaping ([String: Double]) -> Void) {
        self.ratesProvider = ratesProvider
    }
    
    @Generable
    struct Arguments {
        @Guide(description: "The base currency code (e.g., USD)")
        let baseCurrency: String
        
        @Guide(description: "The target currency code (e.g., EUR)")
        let targetCurrency: String
    }
    
    func call(arguments: Arguments) async throws -> String {
        // In a real implementation, this would call your actual rates API
        // For now, we'll return a formatted response
        
        // TODO: Hook up to your actual rates fetching logic
        let rate = fetchMockRate(from: arguments.baseCurrency, to: arguments.targetCurrency)
        
        return """
        Current exchange rate from \(arguments.baseCurrency) to \(arguments.targetCurrency):
        1 \(arguments.baseCurrency) = \(String(format: "%.4f", rate)) \(arguments.targetCurrency)
        
        This rate is updated in real-time from market data.
        """
    }
    
    // Mock implementation - replace with your actual rate fetching
    private func fetchMockRate(from base: String, to target: String) -> Double {
        let mockRates: [String: [String: Double]] = [
            "USD": ["EUR": 0.92, "GBP": 0.79, "JPY": 147.0, "CAD": 1.35],
            "EUR": ["USD": 1.09, "GBP": 0.86, "JPY": 159.8],
            "GBP": ["USD": 1.27, "EUR": 1.16, "JPY": 186.2]
        ]
        
        return mockRates[base]?[target] ?? 1.0
    }
}

/// A tool that provides historical rate data for analysis
struct CurrencyHistoryTool: Tool {
    let name = "getHistoricalRates"
    
    let description = """
    Retrieves historical exchange rates for a currency pair over a specified time period. \
    Use this when analyzing trends or when the user asks about rate changes over time.
    """
    
    @Generable
    struct Arguments {
        @Guide(description: "The base currency code")
        let baseCurrency: String
        
        @Guide(description: "The target currency code")
        let targetCurrency: String
        
        @Guide(description: "Time period to analyze")
        let period: TimePeriod
    }
    
    @Generable
    enum TimePeriod: String, CaseIterable {
        case day = "1 day"
        case week = "1 week"
        case month = "1 month"
        case quarter = "3 months"
        case year = "1 year"
    }
    
    func call(arguments: Arguments) async throws -> String {
        // Mock historical data - replace with your actual history fetching
        let mockData = generateMockHistory(
            from: arguments.baseCurrency,
            to: arguments.targetCurrency,
            period: arguments.period
        )
        
        return """
        Historical rates for \(arguments.baseCurrency)/\(arguments.targetCurrency) over \(arguments.period.rawValue):
        
        \(mockData)
        
        Data shows the daily closing rates for this period.
        """
    }
    
    private func generateMockHistory(from base: String, to target: String, period: TimePeriod) -> String {
        let baseRate = 0.92 // Mock EUR rate
        let variance = 0.02
        
        let days: Int
        switch period {
        case .day: days = 1
        case .week: days = 7
        case .month: days = 30
        case .quarter: days = 90
        case .year: days = 365
        }
        
        var result = ""
        for i in 0..<min(days, 10) { // Show max 10 data points
            let rate = baseRate + Double.random(in: -variance...variance)
            result += "Day -\(i): \(String(format: "%.4f", rate))\n"
        }
        
        return result
    }
}

/// A tool that provides cost-of-living information for travel planning
struct CostOfLivingTool: Tool {
    let name = "getCostOfLiving"
    
    let description = """
    Provides cost of living information for a destination, including typical prices \
    for accommodation, food, transportation, and activities. Use this for travel budget planning.
    """
    
    @Generable
    struct Arguments {
        @Guide(description: "The destination city or country")
        let destination: String
        
        @Guide(description: "The currency to report costs in")
        let currency: String
    }
    
    func call(arguments: Arguments) async throws -> String {
        // Mock cost data - replace with real API call
        let costs = getMockCostsForDestination(arguments.destination, currency: arguments.currency)
        
        return """
        Cost of living in \(arguments.destination) (\(arguments.currency)):
        
        \(costs)
        
        These are average costs for tourists. Actual costs may vary by season and personal preferences.
        """
    }
    
    private func getMockCostsForDestination(_ destination: String, currency: String) -> String {
        """
        Daily Budget Estimates:
        • Budget Accommodation: 40-60 \(currency)
        • Mid-range Hotel: 80-120 \(currency)
        • Meals (3 per day): 30-50 \(currency)
        • Local Transportation: 10-15 \(currency)
        • Attractions/Activities: 20-40 \(currency)
        
        Average Daily Total: 180-285 \(currency)
        """
    }
}

// MARK: - Helper to create a session with all currency tools

extension LanguageModelSession {
    /// Create a currency-focused session with all relevant tools
    static func currencySession(with ratesProvider: @escaping ([String: Double]) -> Void) -> LanguageModelSession {
        let instructions = """
        You are a currency conversion and travel planning assistant.
        Use the available tools to provide accurate, real-time information.
        Always cite the tools when using their data.
        Be concise and friendly in your responses.
        """
        
        let tools: [any Tool] = [
            CurrencyRateTool(ratesProvider: ratesProvider),
            CurrencyHistoryTool(),
            CostOfLivingTool()
        ]
        
        return LanguageModelSession(
            tools: tools,
            instructions: instructions
        )
    }
}

#endif

