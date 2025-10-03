//
//  CurrencyAIModels.swift
//  currency converter
//
//  Structured AI models using Foundation Models @Generable macro
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

// MARK: - Structured Currency Conversion Response

/// A structured AI response for currency conversion with explanation
@Generable
struct CurrencyConversionResponse {
    @Guide(description: "The original amount and currency being converted from")
    let fromAmount: Double
    
    @Guide(description: "The ISO currency code being converted from (e.g., USD)")
    let fromCurrency: String
    
    @Guide(description: "The converted amount in the target currency")
    let toAmount: Double
    
    @Guide(description: "The ISO currency code being converted to (e.g., EUR)")
    let toCurrency: String
    
    @Guide(description: "The exchange rate used for this conversion")
    let exchangeRate: Double
    
    @Guide(description: "A brief, friendly explanation of the conversion (1-2 sentences)")
    let explanation: String
    
    @Guide(description: "Optional context or caveats about the conversion")
    let context: String?
    
    // Example for few-shot prompting
    static let exampleUSDtoEUR = CurrencyConversionResponse(
        fromAmount: 100.0,
        fromCurrency: "USD",
        toAmount: 92.0,
        toCurrency: "EUR",
        exchangeRate: 0.92,
        explanation: "100 US Dollars converts to 92 Euros at today's rate.",
        context: "Exchange rates fluctuate throughout the day."
    )
}

// MARK: - Travel Budget Insights

@Generable
struct TravelBudgetInsight {
    @Guide(description: "The destination country or city")
    let destination: String
    
    @Guide(description: "The budget in local currency")
    let budgetInLocalCurrency: Double
    
    @Guide(description: "The local currency code")
    let localCurrencyCode: String
    
    @Guide(description: "Estimated number of days this budget will last")
    @Guide(.range(1...365))
    let estimatedDays: Int
    
    @Guide(description: "Daily spending recommendations")
    @Guide(.count(3...5))
    let dailyRecommendations: [DailyRecommendation]
    
    @Guide(description: "Important tips or warnings about costs in this destination")
    @Guide(.count(2...4))
    let localCostTips: [String]
    
    @Guide(description: "Overall purchasing power assessment")
    let purchasingPowerLevel: PurchasingPowerLevel
    
    static let exampleParis = TravelBudgetInsight(
        destination: "Paris, France",
        budgetInLocalCurrency: 1500.0,
        localCurrencyCode: "EUR",
        estimatedDays: 7,
        dailyRecommendations: [
            DailyRecommendation(category: "Accommodation", estimatedCost: 80.0, notes: "Budget hotel or hostel"),
            DailyRecommendation(category: "Food", estimatedCost: 50.0, notes: "Mix of restaurants and street food"),
            DailyRecommendation(category: "Transportation", estimatedCost: 15.0, notes: "Metro and walking"),
            DailyRecommendation(category: "Activities", estimatedCost: 30.0, notes: "Museums and attractions")
        ],
        localCostTips: [
            "Restaurants typically include service, but rounding up is appreciated",
            "Metro passes offer better value than single tickets",
            "Many museums are free on the first Sunday of the month"
        ],
        purchasingPowerLevel: .moderate
    )
}

@Generable
struct DailyRecommendation {
    @Guide(description: "The spending category")
    let category: String
    
    @Guide(description: "Estimated daily cost in local currency")
    let estimatedCost: Double
    
    @Guide(description: "Brief notes or tips for this category")
    let notes: String
}

@Generable
enum PurchasingPowerLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case limited = "Limited"
}

// MARK: - Currency Pair Analysis

@Generable
struct CurrencyPairAnalysis {
    @Guide(description: "The base currency code")
    let baseCurrency: String
    
    @Guide(description: "The target currency code")
    let targetCurrency: String
    
    @Guide(description: "Current trend direction")
    let trend: AITrendDirection
    
    @Guide(description: "Brief analysis of recent movement (2-3 sentences)")
    let analysis: String
    
    @Guide(description: "Recommended actions based on the trend")
    @Guide(.count(2...3))
    let recommendations: [String]
    
    @Guide(description: "Confidence level in this analysis (0.0 to 1.0)")
    @Guide(.range(0.0...1.0))
    let confidence: Double
}

@Generable
enum AITrendDirection: String, CaseIterable {
    case rising = "Rising"
    case falling = "Falling"
    case stable = "Stable"
    case volatile = "Volatile"
}

// MARK: - Natural Language Query Parse

@Generable
struct CurrencyQueryParse {
    @Guide(description: "The amount to convert, if specified")
    let amount: Double?
    
    @Guide(description: "The source currency code, if detected")
    let fromCurrency: String?
    
    @Guide(description: "The target currency code, if detected")
    let toCurrency: String?
    
    @Guide(description: "The user's intent category")
    let intent: QueryIntent
    
    @Guide(description: "Whether the query has all required information")
    let isComplete: Bool
    
    @Guide(description: "Friendly message to show the user")
    let responseMessage: String
}

@Generable
enum QueryIntent: String, CaseIterable {
    case conversion = "Conversion"
    case rateInquiry = "Rate Inquiry"
    case travelAdvice = "Travel Advice"
    case currencyInfo = "Currency Information"
    case general = "General Question"
    case comparison = "Comparison"
    case unknown = "Unknown"
}

#endif

