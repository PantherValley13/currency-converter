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
        print("📝 Creating new LanguageModelSession with currency expertise")
        
        let instructions = Instructions {
            """
            You are an expert currency assistant with deep knowledge of global currencies, exchange rates, and international travel.
            
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
            
            IMPORTANT RULES:
            1. Always use official ISO currency codes (USD, EUR, JPY, etc.)
            2. Provide approximate values - you're giving guidance, not financial advice
            3. Include practical context about purchasing power
            4. Mention current trends when relevant
            5. Warn about common scams or pitfalls
            
            TYPICAL EXCHANGE RATES (for reference):
            • 1 USD ≈ 0.92 EUR (Euro)
            • 1 USD ≈ 19 MXN (Mexican Peso)
            • 1 USD ≈ 147 JPY (Japanese Yen)
            • 1 USD ≈ 0.79 GBP (British Pound)
            • 1 USD ≈ 1.35 CAD (Canadian Dollar)
            • 1 USD ≈ 7.2 CNY (Chinese Yuan)
            • 1 USD ≈ 83 INR (Indian Rupee)
            
            Always adapt your response to what the user is actually asking for.
            """
        }
        
        sessionCreationTime = Date()
        return LanguageModelSession(instructions: instructions)
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

