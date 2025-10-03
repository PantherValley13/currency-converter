//
//  CurrencyModels.swift
//  currency converter
//
//  Generable models for LLM-powered currency intelligence
//

import Foundation
import FoundationModels

// MARK: - Main Currency Query Response

@Generable
struct CurrencyResponse {
    @Guide(description: "A clear, engaging title for this response.")
    let title: String
    
    @Guide(description: "The main answer to the user's query.")
    let answer: String
    
    @Guide(description: "What the user is asking about.")
    let queryType: QueryType
    
    @Guide(description: "Detailed conversion information if this is a conversion request.")
    let conversionDetails: ConversionDetails?
    
    @Guide(description: "Travel advice if the query is travel-related.")
    let travelAdvice: TravelAdvice?
    
    @Guide(description: "Currency information if asking about a specific currency.")
    let currencyInfo: CurrencyInfo?
}

// MARK: - Query Type

@Generable
enum QueryType: String, CaseIterable {
    case conversion = "Currency Conversion"
    case currencyInfo = "Currency Information"
    case travelAdvice = "Travel Advice"
    case exchangeRate = "Exchange Rate Inquiry"
    case general = "General Question"
}

// MARK: - Conversion Details

@Generable
struct ConversionDetails {
    @Guide(description: "The amount being converted.")
    let amount: Double
    
    @Guide(description: "Source currency ISO code (e.g., USD).")
    let fromCurrency: String
    
    @Guide(description: "Target currency ISO code (e.g., EUR).")
    let toCurrency: String
    
    @Guide(description: "The converted amount.")
    let result: Double
    
    @Guide(description: "Explanation of the conversion in plain language.")
    let explanation: String
    
    @Guide(description: "Practical context about what this amount can buy.")
    let practicalContext: String?
    
    @Guide(description: "Whether this is a good time to convert.")
    let timingAdvice: String?
}

// MARK: - Travel Advice

@Generable
struct TravelAdvice {
    @Guide(description: "The destination country or region.")
    let destination: String
    
    @Guide(description: "The local currency name and code.")
    let localCurrency: String
    
    @Guide(description: "Typical daily budget in local currency.")
    let dailyBudget: BudgetEstimate
    
    @Guide(description: "Practical tips for using money in this location.")
    @Guide(.count(3...5))
    let moneyTips: [MoneyTip]
    
    @Guide(description: "Important warnings or things to avoid.")
    @Guide(.count(1...3))
    let warnings: [String]
}

@Generable
struct BudgetEstimate {
    @Guide(description: "Budget level: budget, moderate, or luxury.")
    let level: BudgetLevel
    
    @Guide(description: "Daily amount in local currency.")
    let dailyAmount: Double
    
    @Guide(description: "What this budget typically covers.")
    let includes: String
}

@Generable
enum BudgetLevel: String, CaseIterable {
    case budget = "Budget"
    case moderate = "Moderate"
    case luxury = "Luxury"
}

@Generable
struct MoneyTip {
    @Guide(description: "Category of this tip.")
    let category: TipCategory
    
    @Guide(description: "The actual advice.")
    let advice: String
    
    @Guide(description: "Why this matters.")
    let reasoning: String
}

@Generable
enum TipCategory: String, CaseIterable {
    case payment = "Payment Methods"
    case exchange = "Where to Exchange"
    case tipping = "Tipping Culture"
    case safety = "Safety"
    case prices = "Typical Prices"
    case bargaining = "Bargaining"
}

// MARK: - Currency Info

@Generable
struct CurrencyInfo {
    @Guide(description: "The currency name.")
    let name: String
    
    @Guide(description: "ISO currency code.")
    let code: String
    
    @Guide(description: "Symbol used for this currency.")
    let symbol: String
    
    @Guide(description: "Countries or regions that use this currency.")
    @Guide(.count(1...10))
    let usedIn: [String]
    
    @Guide(description: "Interesting facts about this currency.")
    @Guide(.count(2...4))
    let interestingFacts: [String]
    
    @Guide(description: "Common denominations of bills and coins.")
    let denominations: String
}

// MARK: - Examples for Few-Shot Prompting

extension CurrencyResponse {
    static let exampleConversion = CurrencyResponse(
        title: "Converting 100 USD to EUR",
        answer: "100 US Dollars converts to approximately 92 Euros at current exchange rates.",
        queryType: .conversion,
        conversionDetails: ConversionDetails(
            amount: 100.0,
            fromCurrency: "USD",
            toCurrency: "EUR",
            result: 92.0,
            explanation: "At today's rate of 1 USD = 0.92 EUR, your 100 dollars will give you 92 euros.",
            practicalContext: "This is enough for a nice dinner for two at a mid-range restaurant in Paris, or about 10-12 cappuccinos at a typical European cafe.",
            timingAdvice: "The current rate is within normal range. If you're traveling soon, this is a reasonable time to exchange."
        ),
        travelAdvice: nil,
        currencyInfo: nil
    )
    
    static let exampleCurrencyInfo = CurrencyResponse(
        title: "About the Japanese Yen (JPY)",
        answer: "Japan's currency is the Japanese Yen (JPY), one of the most traded currencies in the world.",
        queryType: .currencyInfo,
        conversionDetails: nil,
        travelAdvice: nil,
        currencyInfo: CurrencyInfo(
            name: "Japanese Yen",
            code: "JPY",
            symbol: "¥",
            usedIn: ["Japan"],
            interestingFacts: [
                "The yen is the third most traded currency globally, after the US dollar and euro.",
                "Japan's coins have different designs representing flowers, trees, and cultural symbols.",
                "The ¥1 coin has a hole in the middle, originally to save metal during production."
            ],
            denominations: "Coins: ¥1, ¥5, ¥10, ¥50, ¥100, ¥500. Bills: ¥1,000, ¥2,000, ¥5,000, ¥10,000"
        )
    )
    
    static let exampleTravelAdvice = CurrencyResponse(
        title: "Money Tips for Traveling to Mexico",
        answer: "Mexico uses the Mexican Peso (MXN). Here's everything you need to know about money in Mexico.",
        queryType: .travelAdvice,
        conversionDetails: nil,
        travelAdvice: TravelAdvice(
            destination: "Mexico",
            localCurrency: "Mexican Peso (MXN)",
            dailyBudget: BudgetEstimate(
                level: .moderate,
                dailyAmount: 1500.0,
                includes: "Accommodations, three meals, local transportation, and some activities. About 80 USD equivalent."
            ),
            moneyTips: [
                MoneyTip(
                    category: .payment,
                    advice: "Credit cards are widely accepted in cities and tourist areas, but always carry cash for small vendors, street food, and tips.",
                    reasoning: "Many local markets, taxis, and small restaurants only accept cash."
                ),
                MoneyTip(
                    category: .exchange,
                    advice: "Use ATMs from major Mexican banks (Banamex, BBVA, Santander) rather than airport exchanges.",
                    reasoning: "Airport exchanges can charge 10-15% worse rates. Bank ATMs offer fair rates with minimal fees."
                ),
                MoneyTip(
                    category: .tipping,
                    advice: "Tip 10-15% at restaurants, 20-50 pesos for hotel staff, and round up for taxis.",
                    reasoning: "Tipping is customary and service staff often rely on tips as part of their income."
                )
            ],
            warnings: [
                "Avoid exchanging money with street vendors - stick to banks and official exchange houses (casas de cambio).",
                "Notify your bank before traveling to avoid having your card blocked for suspicious foreign activity."
            ]
        ),
        currencyInfo: nil
    )
}

