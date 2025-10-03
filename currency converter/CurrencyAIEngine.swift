//
//  CurrencyAIEngine.swift
//  currency converter
//
//  AI Engine for currency intelligence using Foundation Models
//

import Foundation
import FoundationModels

final class CurrencyAIEngine {
    static let shared = CurrencyAIEngine()
    
    private init() {
        print("🔧 CurrencyAIEngine: Initializing")
    }
    
    // MARK: - Foundation Models Setup
    
    private let model = SystemLanguageModel.default
    
    private var session: LanguageModelSession!
    private var sessionCreationTime: Date?
    
    private func createSession() -> LanguageModelSession {
        print("📝 Creating new LanguageModelSession with currency expertise and tools")
        
        let instructions = Instructions {
            """
            You are an expert currency assistant with access to real-time exchange rates and historical data.
            
            YOUR EXPERTISE:
            • Currency conversions and exchange rates
            • Travel money advice for 100+ countries
            • Cultural payment customs and tipping
            • Practical budgeting and money safety
            
            YOUR STYLE:
            • Friendly and helpful, never condescending
            • Specific and actionable, not vague
            • Include interesting facts when relevant
            • Give real-world context (what money can buy)
            
            REFERENCE RATES (for quick estimates):
            • USD/EUR ≈ 0.92  • USD/GBP ≈ 0.79  • USD/JPY ≈ 147
            • USD/CAD ≈ 1.35  • USD/MXN ≈ 19    • USD/CNY ≈ 7.2
            • USD/INR ≈ 83    • USD/AUD ≈ 1.52  • EUR/GBP ≈ 0.86
            
            WHEN TO USE TOOLS (you have getCurrentExchangeRate and getHistoricalRates):
            
            ✅ USE TOOLS WHEN:
            - User asks for "exact", "precise", "current", "today's" rate
            - User asks "should I exchange now?" (needs real rate)
            - User asks about rate changes or trends (use getHistoricalRates)
            - User mentions specific amounts and needs accurate conversion
            - Currency is not in reference list above
            - User is making important financial decisions
            
            ❌ DON'T USE TOOLS WHEN:
            - User asks "about how much", "approximately", "roughly"
            - General questions like "What currency does X use?"
            - Cultural/travel advice (tipping, payment methods)
            - Quick ballpark estimates
            - User just wants general info
            
            IMPORTANT:
            - When using tools, say "using real-time rates" or "checking current rate"
            - When using estimates, say "approximately" or "around"
            - Always be clear which you're using!
            
            RULES:
            1. Use official ISO currency codes (USD, EUR, JPY)
            2. Provide context about purchasing power
            3. Warn about scams or pitfalls
            4. Be concise (2-3 sentences when possible)
            """
        }
        
        // Create tools that connect to live data
        let tools: [any Tool] = createCurrencyTools()
        
        sessionCreationTime = Date()
        return LanguageModelSession(tools: tools, instructions: instructions)
    }
    
    // MARK: - Tool Creation
    
    private func createCurrencyTools() -> [any Tool] {
        var tools: [any Tool] = []
        
        #if canImport(FoundationModels)
        // Tool 1: Get current exchange rate
        tools.append(LiveCurrencyRateTool())
        
        // Tool 2: Get historical rates (if needed)
        // tools.append(LiveHistoryTool())
        #endif
        
        return tools
    }
    
    private func ensureSessionIsValid() {
        if session == nil {
            print("🔄 No session exists - creating new one")
            session = createSession()
        }
    }
    
    /// Reset the LLM session - call this when starting a new conversation or after errors
    func resetSession() {
        print("🔄 Resetting LLM session...")
        if let creationTime = sessionCreationTime {
            let age = Date().timeIntervalSince(creationTime)
            print("   Previous session age: \(String(format: "%.1f", age))s")
        }
        session = createSession()
        print("✅ New session created and ready")
    }
    
    // MARK: - Public API
    
    var isAvailable: Bool {
        model.availability == .available
    }
    
    var availabilityDescription: String {
        switch model.availability {
        case .available:
            return "AI currency assistant ready"
        case .unavailable(.deviceNotEligible):
            return "Device not eligible for Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Enable Apple Intelligence in Settings"
        case .unavailable(.modelNotReady):
            return "Model downloading..."
        case .unavailable(let other):
            return "Unavailable: \(other)"
        }
    }
    
    func prewarm() {
        guard isAvailable else {
            print("⚠️ Cannot prewarm: \(availabilityDescription)")
            return
        }
        ensureSessionIsValid()
        print("🔥 Pre-warming currency AI...")
        session.prewarm()
        print("✅ Currency AI ready")
    }
    
    // MARK: - Core Methods
    
    /// Answer any currency-related query with structured response
    func answerQuery(_ query: String, conversationHistory: [(userQuery: String, aiResponse: String)] = []) async -> CurrencyResponse? {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🧠 CurrencyAIEngine: Processing Query")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📝 Query: \"\(query)\"")
        print("📏 Query length: \(query.count) characters")
        print("💭 Context: \(conversationHistory.count) previous messages")
        
        guard isAvailable else {
            print("❌ Model not available")
            return nil
        }
        
        // Ensure session is valid before processing
        ensureSessionIsValid()
        
        // Limit query length to prevent token overflow
        let maxQueryLength = 300
        let trimmedQuery = query.count > maxQueryLength ? String(query.prefix(maxQueryLength)) : query
        
        if query.count > maxQueryLength {
            print("⚠️  Query truncated from \(query.count) to \(maxQueryLength) chars")
        }
        
        // Build prompt with conversation context (extended to 7 exchanges)
        // Provides longer memory for complex multi-turn conversations
        let recentHistory = conversationHistory.suffix(7)
        
        let prompt = Prompt {
            // Include recent conversation context if available
            if !recentHistory.isEmpty {
                "Previous conversation:"
                for exchange in recentHistory {
                    "User: \(exchange.userQuery)"
                    "Assistant: \(exchange.aiResponse)"
                }
                ""
            }
            
            "Current question (answer BRIEFLY in 2-3 sentences):"
            "\(trimmedQuery)"
            ""
            "Keep your answer SHORT and focused."
        }
        
        do {
            print("🚀 Sending request...")
            let response = try await session.respond(
                to: prompt,
                generating: CurrencyResponse.self,
                options: GenerationOptions(sampling: .greedy)
            )
            
            let result = response.content
            print("✅ Response generated successfully")
            print("📊 Type: \(result.queryType.rawValue)")
            print("💬 Title: \"\(result.title)\"")
            print("📏 Answer length: \(result.answer.count) characters")
            
            return result
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            
            let isTokenLimitError = error.localizedDescription.lowercased().contains("token") || 
                                   error.localizedDescription.lowercased().contains("length") ||
                                   error.localizedDescription.lowercased().contains("context")
            
            // If token limit error, reset session and try without context
            if isTokenLimitError {
                print("⚠️  Token limit hit - resetting session...")
                resetSession()
                
                if !conversationHistory.isEmpty {
                    print("⚠️  Retrying WITHOUT context...")
                    return await answerQuery(trimmedQuery, conversationHistory: [])
                } else {
                    print("⚠️  Already no context - trying minimal prompt...")
                    return await answerQueryMinimal(trimmedQuery)
                }
            }
            
            // For other errors, also reset session to ensure clean state
            print("⚠️  Resetting session due to error...")
            resetSession()
            
            return nil
        }
    }
    
    /// Minimal fallback when token limits are exceeded
    private func answerQueryMinimal(_ query: String) async -> CurrencyResponse? {
        print("🔄 Minimal query attempt...")
        ensureSessionIsValid()
        
        // Ultra-short prompt
        let minimalPrompt = Prompt {
            "Brief answer: \(String(query.prefix(100)))"
        }
        
        do {
            let response = try await session.respond(
                to: minimalPrompt,
                generating: CurrencyResponse.self,
                options: GenerationOptions(sampling: .greedy)
            )
            
            print("✅ Minimal query succeeded")
            return response.content
        } catch {
            print("❌ Minimal query failed: \(error.localizedDescription)")
            print("⚠️  Resetting session after minimal query failure...")
            resetSession()
            return nil
        }
    }
    
    /// Stream a response for better UX on longer queries
    func streamQueryAnswer(_ query: String, onUpdate: @escaping (CurrencyResponse.PartiallyGenerated) -> Void) async {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌊 CurrencyAIEngine: Streaming Response")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📝 Query: \"\(query)\"")
        
        ensureSessionIsValid()
        
        guard isAvailable else {
            print("❌ Model not available")
            return
        }
        
        let prompt = Prompt {
            "Answer this currency question: \"\(query)\""
            "Provide a complete, helpful response."
            ""
            "Here are examples:"
            CurrencyResponse.exampleConversion
            CurrencyResponse.exampleCurrencyInfo
            CurrencyResponse.exampleTravelAdvice
        }
        
        do {
            print("🚀 Starting stream...")
            var chunkCount = 0
            
            for try await snapshot in session.streamResponse(
                to: prompt,
                generating: CurrencyResponse.self,
                options: GenerationOptions(sampling: .greedy)
            ) {
                chunkCount += 1
                onUpdate(snapshot.content)
                
                if chunkCount % 5 == 0 {
                    print("📦 Chunk \(chunkCount)")
                }
            }
            
            print("✅ Stream complete - \(chunkCount) chunks")
        } catch {
            print("❌ Stream error: \(error)")
        }
    }
    
    /// Quick conversion without full response structure
    func quickConvert(amount: Double, from: String, to: String) async -> String? {
        let query = "Convert \(amount) \(from) to \(to)"
        
        guard let response = await answerQuery(query) else {
            return nil
        }
        
        return response.answer
    }
}

// MARK: - Live Currency Rate Tool

#if canImport(FoundationModels)

/// Tool that fetches real-time exchange rates from the API
struct LiveCurrencyRateTool: Tool {
    let name = "getCurrentExchangeRate"
    
    let description = """
    Gets the current, real-time exchange rate between two currencies.
    Use this when the user needs precise, up-to-date rates for conversions or comparisons.
    Returns the live rate from market data.
    """
    
    @Generable
    struct Arguments {
        @Guide(description: "The base currency code (e.g., 'USD', 'EUR')")
        let baseCurrency: String
        
        @Guide(description: "The target currency code (e.g., 'EUR', 'JPY')")
        let targetCurrency: String
    }
    
    func call(arguments: Arguments) async throws -> String {
        print("🔧 Tool called: getCurrentExchangeRate(\(arguments.baseCurrency) → \(arguments.targetCurrency))")
        
        // Fetch live rate from API
        do {
            let rate = try await fetchLiveRate(from: arguments.baseCurrency, to: arguments.targetCurrency)
            
            let response = """
            Real-time exchange rate:
            1 \(arguments.baseCurrency) = \(String(format: "%.4f", rate)) \(arguments.targetCurrency)
            
            This is the current market rate updated in real-time.
            """
            
            print("✅ Tool returned: \(String(format: "%.4f", rate))")
            return response
            
        } catch {
            print("❌ Tool error: \(error.localizedDescription)")
            
            // Fallback to approximate rate if API fails
            let fallbackRate = getApproximateRate(from: arguments.baseCurrency, to: arguments.targetCurrency)
            return """
            Approximate exchange rate:
            1 \(arguments.baseCurrency) ≈ \(String(format: "%.4f", fallbackRate)) \(arguments.targetCurrency)
            
            (Using reference rate - live data temporarily unavailable)
            """
        }
    }
    
    // Fetch real rate from API
    private func fetchLiveRate(from base: String, to target: String) async throws -> Double {
        // Use exchangerate.host API
        let urlString = "https://api.exchangerate.host/latest?base=\(base)&symbols=\(target)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct RateResponse: Codable {
            let rates: [String: Double]
        }
        
        let decoded = try JSONDecoder().decode(RateResponse.self, from: data)
        guard let rate = decoded.rates[target] else {
            throw URLError(.cannotParseResponse)
        }
        
        return rate
    }
    
    // Fallback approximate rates
    private func getApproximateRate(from base: String, to target: String) -> Double {
        let rates: [String: [String: Double]] = [
            "USD": ["EUR": 0.92, "GBP": 0.79, "JPY": 147.0, "CAD": 1.35, "MXN": 19.0, "CNY": 7.2, "INR": 83.0, "AUD": 1.52],
            "EUR": ["USD": 1.09, "GBP": 0.86, "JPY": 160.0, "CAD": 1.47, "MXN": 20.7, "CNY": 7.85],
            "GBP": ["USD": 1.27, "EUR": 1.16, "JPY": 186.0, "CAD": 1.71, "MXN": 24.1],
            "JPY": ["USD": 0.0068, "EUR": 0.0063, "GBP": 0.0054],
            "CAD": ["USD": 0.74, "EUR": 0.68, "GBP": 0.58, "JPY": 108.9],
            "MXN": ["USD": 0.053, "EUR": 0.048, "GBP": 0.041],
            "CNY": ["USD": 0.139, "EUR": 0.127, "GBP": 0.109],
            "INR": ["USD": 0.012, "EUR": 0.011, "GBP": 0.0095]
        ]
        
        return rates[base]?[target] ?? 1.0
    }
}

#endif

