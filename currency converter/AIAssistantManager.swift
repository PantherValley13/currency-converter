//
//  AIAssistantManager.swift
//  currency converter
//
//  AI-powered features using Apple Intelligence
//

import Foundation
import SwiftUI
import Combine

#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

/// Manager for AI-powered intelligent features in the currency converter
final class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()
    
    // MARK: - Published State
    @Published var smartSuggestions: [SmartSuggestion] = []
    @Published var conversationHistory: [ConversationMessage] = []
    @Published var isProcessing: Bool = false
    @Published var travelInsights: TravelInsight?
    @Published var budgetRecommendation: BudgetRecommendation?
    
    private init() {}
    
    @MainActor
    private func updateUI() {
        // Helper for UI updates
    }
    
    // MARK: - AI Features
    
    /// Natural Language Query Processing - 100% LLM-Driven
    /// Uses on-device LLM with structured outputs to parse queries
    /// No hardcoded regex or pattern matching!
    func processNaturalLanguageQuery(_ query: String, context: String? = nil) async -> ConversionRequest? {
        isProcessing = true
        defer { isProcessing = false }
        
        print("🔍 AIAssistantManager: Processing query (LLM-powered)")
        print("├─ Query: \"\(query)\"")
        print("└─ Context: \(context ?? "nil")")
        
        // Use LLM to parse the query with structured output
        guard let parsed = await AIEngine.shared.parseQuery(query, context: context) else {
            print("⚠️  LLM parsing returned nil")
            return nil
        }
        
        // Check if it's a conversion intent with complete information
        guard parsed.intent == .conversion else {
            print("ℹ️  Not a conversion intent: \(parsed.intent.rawValue)")
            return nil
        }
        
        guard parsed.isComplete,
              let from = parsed.fromCurrency,
              let to = parsed.toCurrency else {
            print("⚠️  Incomplete conversion data:")
            print("├─ From: \(parsed.fromCurrency ?? "nil")")
            print("├─ To: \(parsed.toCurrency ?? "nil")")
            print("└─ Complete: \(parsed.isComplete)")
            return nil
        }
        
        let amount = parsed.amount ?? 1.0
        
        print("✅ LLM parsed conversion:")
        print("├─ Amount: \(amount)")
        print("├─ From: \(from)")
        print("├─ To: \(to)")
        print("└─ Response: \"\(parsed.responseMessage)\"")
        
        return ConversionRequest(
            amount: amount,
            baseCurrency: from,
            targetCurrency: to,
            userQuery: query,
            responseMessage: parsed.responseMessage
        )
    }
    
    /// Smart Suggestions based on user behavior and context
    func generateSmartSuggestions(
        basedOn history: [ConversionHistory],
        currentLocation: String? = nil,
        timeOfDay: Date = Date()
    ) async -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Pattern recognition from history
        if let commonPair = findMostCommonCurrencyPair(in: history) {
            suggestions.append(SmartSuggestion(
                title: "Frequent Conversion",
                description: "You often convert \(commonPair.base) to \(commonPair.target)",
                action: .quickPair(base: commonPair.base, target: commonPair.target),
                confidence: 0.9
            ))
        }
        
        // Time-based suggestions
        if isWeekend(timeOfDay) {
            suggestions.append(SmartSuggestion(
                title: "Weekend Travel",
                description: "Planning a trip? Check popular travel currencies",
                action: .showTravelCurrencies,
                confidence: 0.7
            ))
        }
        
        // Amount pattern recognition
        if let commonAmount = findMostCommonAmount(in: history) {
            suggestions.append(SmartSuggestion(
                title: "Quick Amount",
                description: "Set amount to \(formatAmount(commonAmount))",
                action: .setAmount(commonAmount),
                confidence: 0.8
            ))
        }
        
        return suggestions
    }
    
    /// Intelligent Travel Assistant
    func generateTravelInsights(
        destination: String,
        budgetInBaseCurrency: Double,
        baseCurrency: String,
        destinationCurrency: String,
        currentRate: Double
    ) async -> TravelInsight {
        let convertedBudget = budgetInBaseCurrency * currentRate
        
        // Calculate purchasing power
        let purchasingPower = calculatePurchasingPower(
            amount: convertedBudget,
            currency: destinationCurrency
        )
        
        // Generate recommendations
        let recommendations = generateTravelRecommendations(
            destination: destination,
            budget: convertedBudget,
            currency: destinationCurrency,
            purchasingPower: purchasingPower
        )
        
        return TravelInsight(
            destination: destination,
            budgetInLocal: convertedBudget,
            localCurrency: destinationCurrency,
            purchasingPower: purchasingPower,
            recommendations: recommendations,
            bestTimeToExchange: predictBestExchangeTime(
                baseCurrency: baseCurrency,
                targetCurrency: destinationCurrency
            )
        )
    }
    
    /// Smart Budget Recommendations
    func generateBudgetRecommendation(
        income: Double,
        currency: String,
        spendingHistory: [ConversionHistory]
    ) async -> BudgetRecommendation {
        // Analyze spending patterns
        let averageMonthlySpending = calculateAverageSpending(from: spendingHistory)
        let spendingByCategory = categorizeSpendings(spendingHistory)
        let mostFrequentPairText = findMostCommonCurrencyPair(in: spendingHistory).map { "\($0.base) to \($0.target)" } ?? "N/A"
        
        let insights = [
            "Your average conversion amount is \(formatAmount(averageMonthlySpending))",
            "Most frequent currency pair: \(mostFrequentPairText)",
            generateSavingsInsight(income: income, spending: averageMonthlySpending)
        ]
        
        return BudgetRecommendation(
            recommendedBudget: income * 0.7, // 70% spending rule
            averageSpending: averageMonthlySpending,
            insights: insights,
            savingsGoal: income * 0.3
        )
    }
    
    /// Predict Rate Trends using historical data
    func predictRateTrend(
        baseCurrency: String,
        targetCurrency: String,
        historicalRates: [RateDataPoint]
    ) async -> RateTrendPrediction {
        guard historicalRates.count >= 7 else {
            return RateTrendPrediction(
                direction: .stable,
                confidence: 0.0,
                recommendation: "Not enough data for prediction"
            )
        }
        
        // Calculate trend using simple moving average
        let recentRates = Array(historicalRates.suffix(7))
        let olderRates = Array(historicalRates.prefix(7))
        
        let recentAvg = recentRates.map { $0.rate }.reduce(0, +) / Double(recentRates.count)
        let olderAvg = olderRates.map { $0.rate }.reduce(0, +) / Double(olderRates.count)
        
        let change = (recentAvg - olderAvg) / olderAvg * 100
        
        let direction: TrendDirection
        let recommendation: String
        
        if change > 1.0 {
            direction = .rising
            recommendation = "Rate is trending up. Consider converting now if you're receiving \(targetCurrency)."
        } else if change < -1.0 {
            direction = .falling
            recommendation = "Rate is trending down. Consider waiting if you're receiving \(targetCurrency)."
        } else {
            direction = .stable
            recommendation = "Rate is relatively stable. Good time for conversion."
        }
        
        return RateTrendPrediction(
            direction: direction,
            confidence: min(abs(change) / 5.0, 1.0),
            recommendation: recommendation
        )
    }
    
    /// Smart Alert Recommendations
    func recommendAlerts(
        baseCurrency: String,
        targetCurrency: String,
        currentRate: Double,
        historicalRates: [RateDataPoint]
    ) async -> [AlertRecommendation] {
        var recommendations: [AlertRecommendation] = []
        
        guard !historicalRates.isEmpty else { return recommendations }
        
        // Calculate statistics
        let rates = historicalRates.map { $0.rate }
        let average = rates.reduce(0, +) / Double(rates.count)
        let max = rates.max() ?? currentRate
        let min = rates.min() ?? currentRate
        
        // Recommend alerts based on historical volatility
        if currentRate < average {
            recommendations.append(AlertRecommendation(
                type: .above,
                threshold: average,
                reason: "Rate is below historical average (\(String(format: "%.4f", average))). Set alert to notify when it rises."
            ))
        }
        
        if currentRate > average {
            recommendations.append(AlertRecommendation(
                type: .below,
                threshold: average,
                reason: "Rate is above historical average (\(String(format: "%.4f", average))). Set alert for when it drops."
            ))
        }
        
        // Recommend alerts at support/resistance levels
        if currentRate != max {
            recommendations.append(AlertRecommendation(
                type: .above,
                threshold: max * 0.98, // 2% below maximum
                reason: "Near recent high. Alert at \(String(format: "%.4f", max * 0.98)) to catch upward momentum."
            ))
        }
        
        return recommendations
    }
    
    /// Voice Command Interpretation - LLM-Powered
    func interpretVoiceCommand(_ command: String) async -> VoiceCommandResult {
        let lowercased = command.lowercased()
        
        // Try LLM parsing first for conversions and rate inquiries
        if lowercased.contains("convert") || lowercased.contains("change") || 
           lowercased.contains("rate") || lowercased.contains("exchange") {
            
            // Use LLM to parse the command
            if let parsed = await AIEngine.shared.parseQuery(command, context: nil) {
                switch parsed.intent {
                case .conversion:
                    // Convert to ConversionRequest if complete
                    if parsed.isComplete,
                       let from = parsed.fromCurrency,
                       let to = parsed.toCurrency {
                        let request = ConversionRequest(
                            amount: parsed.amount ?? 1.0,
                            baseCurrency: from,
                            targetCurrency: to,
                            userQuery: command,
                            responseMessage: parsed.responseMessage
                        )
                        return .conversion(request)
                    }
                    
                case .rateInquiry:
                    // Rate inquiry
                    if let from = parsed.fromCurrency,
                       let to = parsed.toCurrency {
                        return .rateInquiry(base: from, target: to)
                    }
                    
                default:
                    break
                }
            }
        }
        
        // Alert commands
        if lowercased.contains("alert") || lowercased.contains("notify") {
            return .createAlert(command)
        }
        
        // History commands
        if lowercased.contains("history") || lowercased.contains("past") {
            return .showHistory
        }
        
        return .unknown(command)
    }
    
    /// Context-Aware Amount Suggestions
    func suggestAmounts(
        basedOn context: ConversionContext,
        history: [ConversionHistory]
    ) async -> [Double] {
        var amounts: Set<Double> = []
        
        // Common amounts from history
        let historicalAmounts = history.map { Double(truncating: $0.amount as NSDecimalNumber) }
        if let mostCommon = findMostCommonAmount(in: history) {
            amounts.insert(mostCommon)
        }
        
        // Context-based suggestions
        switch context {
        case .shopping:
            amounts.formUnion([10, 20, 50, 100, 200])
        case .travel:
            amounts.formUnion([100, 250, 500, 1000, 2000])
        case .business:
            amounts.formUnion([500, 1000, 5000, 10000])
        case .daily:
            amounts.formUnion([5, 10, 25, 50, 100])
        }
        
        return Array(amounts).sorted()
    }
    
    /// Generate Conversational Response
    func generateConversationalResponse(
        for query: String,
        withResult result: Double,
        baseCurrency: String,
        targetCurrency: String
    ) -> String {
        let responses = [
            "I've converted that for you! \(formatAmount(result)) \(targetCurrency).",
            "Here you go: \(formatAmount(result)) \(targetCurrency).",
            "The result is \(formatAmount(result)) \(targetCurrency).",
            "That would be \(formatAmount(result)) \(targetCurrency).",
            "Converting... Done! \(formatAmount(result)) \(targetCurrency)."
        ]
        
        return responses.randomElement() ?? "Result: \(formatAmount(result)) \(targetCurrency)"
    }
    
    // MARK: - Helper Methods
    // NOTE: Currency parsing now uses LLM with structured outputs (AIEngine.parseQuery)
    // No more hardcoded regex or pattern matching!
    
    private func findMostCommonCurrencyPair(in history: [ConversionHistory]) -> (base: String, target: String)? {
        guard !history.isEmpty else { return nil }
        
        let pairs = history.map { ($0.baseCurrency, $0.targetCurrency) }
        let grouped = Dictionary(grouping: pairs) { "\($0.0)-\($0.1)" }
        let mostCommon = grouped.max { $0.value.count < $1.value.count }
        
        guard let pair = mostCommon?.value.first else { return nil }
        return (base: pair.0, target: pair.1)
    }
    
    private func findMostCommonAmount(in history: [ConversionHistory]) -> Double? {
        guard !history.isEmpty else { return nil }
        
        let amounts = history.map { Double(truncating: $0.amount as NSDecimalNumber) }
        let grouped = Dictionary(grouping: amounts) { $0 }
        let mostCommon = grouped.max { $0.value.count < $1.value.count }
        
        return mostCommon?.key
    }
    
    private func calculateAverageSpending(from history: [ConversionHistory]) -> Double {
        guard !history.isEmpty else { return 0 }
        
        let total = history.reduce(0.0) { $0 + Double(truncating: $1.amount as NSDecimalNumber) }
        return total / Double(history.count)
    }
    
    private func categorizeSpendings(_ history: [ConversionHistory]) -> [String: Double] {
        // Simple categorization based on amount ranges
        var categories: [String: Double] = [
            "Small (<50)": 0,
            "Medium (50-200)": 0,
            "Large (>200)": 0
        ]
        
        for conversion in history {
            let amount = Double(truncating: conversion.amount as NSDecimalNumber)
            if amount < 50 {
                categories["Small (<50)"]! += amount
            } else if amount < 200 {
                categories["Medium (50-200)"]! += amount
            } else {
                categories["Large (>200)"]! += amount
            }
        }
        
        return categories
    }
    
    private func generateSavingsInsight(income: Double, spending: Double) -> String {
        let savingsRate = (income - spending) / income * 100
        
        if savingsRate > 30 {
            return "Great job! You're saving \(String(format: "%.1f", savingsRate))% of your income."
        } else if savingsRate > 20 {
            return "You're saving \(String(format: "%.1f", savingsRate))%. Consider increasing to 30% or more."
        } else {
            return "Consider saving more. Current rate: \(String(format: "%.1f", savingsRate))%"
        }
    }
    
    private func calculatePurchasingPower(amount: Double, currency: String) -> PurchasingPower {
        // Simplified purchasing power calculation
        // In production, this would use real data from APIs
        let baselineCost = 50.0 // Average daily cost in USD
        let adjustedCost: Double
        
        switch currency {
        case "EUR": adjustedCost = 55.0
        case "GBP": adjustedCost = 60.0
        case "JPY": adjustedCost = 30.0
        case "INR": adjustedCost = 15.0
        case "BRL": adjustedCost = 25.0
        default: adjustedCost = baselineCost
        }
        
        let estimatedDays = Int(amount / adjustedCost)
        
        return PurchasingPower(
            estimatedDays: estimatedDays,
            dailyBudget: adjustedCost,
            category: estimatedDays > 30 ? .excellent : estimatedDays > 14 ? .good : .moderate
        )
    }
    
    private func generateTravelRecommendations(
        destination: String,
        budget: Double,
        currency: String,
        purchasingPower: PurchasingPower
    ) -> [String] {
        var recommendations: [String] = []
        
        recommendations.append("Your budget of \(formatAmount(budget)) \(currency) should last approximately \(purchasingPower.estimatedDays) days.")
        
        if purchasingPower.category == .excellent {
            recommendations.append("Excellent budget! You'll have plenty for activities and dining out.")
        } else if purchasingPower.category == .good {
            recommendations.append("Good budget for a comfortable trip with some splurges.")
        } else {
            recommendations.append("Budget carefully to make the most of your trip.")
        }
        
        recommendations.append("Set a daily spending limit of \(formatAmount(purchasingPower.dailyBudget)) \(currency)")
        
        return recommendations
    }
    
    private func predictBestExchangeTime(baseCurrency: String, targetCurrency: String) -> String {
        // Simplified prediction
        // In production, this would use ML models and real-time data
        return "Based on recent trends, rates are typically better mid-week."
    }
    
    private func isWeekend(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - Data Models

struct ConversionRequest {
    let amount: Double
    let baseCurrency: String
    let targetCurrency: String
    let userQuery: String
    let responseMessage: String? // LLM-generated friendly response (optional for backward compatibility)
}

struct SmartSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let action: SuggestionAction
    let confidence: Double
}

enum SuggestionAction {
    case quickPair(base: String, target: String)
    case setAmount(Double)
    case showTravelCurrencies
    case createAlert(base: String, target: String, threshold: Double)
}

struct TravelInsight {
    let destination: String
    let budgetInLocal: Double
    let localCurrency: String
    let purchasingPower: PurchasingPower
    let recommendations: [String]
    let bestTimeToExchange: String
}

struct PurchasingPower {
    let estimatedDays: Int
    let dailyBudget: Double
    let category: PowerCategory
    
    enum PowerCategory {
        case excellent, good, moderate, limited
    }
}

struct BudgetRecommendation {
    let recommendedBudget: Double
    let averageSpending: Double
    let insights: [String]
    let savingsGoal: Double
}

struct RateDataPoint {
    let date: Date
    let rate: Double
}

struct RateTrendPrediction {
    let direction: TrendDirection
    let confidence: Double
    let recommendation: String
}

enum TrendDirection {
    case rising, falling, stable
}

struct AlertRecommendation: Identifiable {
    let id = UUID()
    let type: AlertType
    let threshold: Double
    let reason: String
    
    enum AlertType {
        case above, below
    }
}

enum VoiceCommandResult {
    case conversion(ConversionRequest)
    case rateInquiry(base: String, target: String)
    case createAlert(String)
    case showHistory
    case unknown(String)
}

enum ConversionContext {
    case shopping, travel, business, daily
}

struct ConversationMessage: Identifiable {
    let id = UUID()
    var text: String  // var so we can update during streaming
    let isUser: Bool
    let timestamp: Date
}

