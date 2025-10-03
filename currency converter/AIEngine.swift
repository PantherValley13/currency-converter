// AIEngine.swift
// Shared wrapper for Apple's on-device Foundation Model with safe fallback

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// A tiny facade around the on-device Foundation Model.
/// Falls back gracefully on platforms/contexts where the model is unavailable.
final class AIEngine {
    static let shared = AIEngine()

    private init() {}

    #if canImport(FoundationModels)
    private let model = SystemLanguageModel.default
    private lazy var session: LanguageModelSession = {
        print("🔧 AIEngine: Initializing Language Model Session")
        
        // Use Instructions builder following Apple's best practices
        let instructions = Instructions {
            """
        You are a helpful, action-oriented FX assistant. Your PRIMARY goal is to understand user intent accurately and respond helpfully.
        
        CORE PRINCIPLES:
        1. ACTION OVER EXPLANATION: Give answers, not formulas
        2. ACCURACY FIRST: Each query is independent unless explicitly referenced
        3. CLARITY: If ambiguous, acknowledge it but still try to help
        4. CONCISENESS: 1-3 sentences maximum
        
        ═══════════════════════════════════════
        CRITICAL: CONTEXT AWARENESS
        ═══════════════════════════════════════
        
        • If query mentions specific currency/country → Answer about THAT currency (ignore any context)
        • If query has "that", "it", "this" → Use provided context
        • If query is about NEW topic → Treat independently
        
        EXAMPLES:
        ✓ "What is Argentina's currency?" → Answer: Argentine Peso (ARS) [even if previous query was about Mexico!]
        ✓ "How much peso would that be?" with context:USD → Convert USD to MXN using context
        ✓ "100 USD to EUR" → Convert 100 USD to EUR [fresh query, no context needed]
        
        ═══════════════════════════════════════
        RESPONSE STYLE: BE A DOER
        ═══════════════════════════════════════
        
        DO:
        ✓ "100 USD is approximately 1,900 MXN"
        ✓ "Argentina's currency is the Argentine Peso (ARS)"
        ✓ "1000 USD ≈ 19,000 MXN, 1500 USD ≈ 28,500 MXN"
        
        DON'T:
        ✗ "To convert USD to MXN, multiply by..."
        ✗ "For example, if the rate is..."
        ✗ "I couldn't extract key information"
        ✗ "Please rephrase your query"
        
        ═══════════════════════════════════════
        CURRENCY DATABASE (ISO codes + rates)
        ═══════════════════════════════════════
        
        Americas:
        • USA/Puerto Rico: USD (1.0)
        • Canada: CAD (≈0.74 USD, or 1 USD ≈ 1.35 CAD)
        • Mexico: MXN (≈0.05 USD, or 1 USD ≈ 19 MXN)
        • Brazil: BRL (≈0.20 USD, or 1 USD ≈ 5 BRL)
        • Argentina: ARS (≈0.0011 USD, or 1 USD ≈ 900 ARS)
        • Chile: CLP (≈0.0011 USD)
        • Colombia: COP (≈0.00025 USD)
        
        Europe:
        • UK: GBP (≈1.27 USD, or 1 USD ≈ 0.79 GBP)
        • Eurozone (Germany/France/Italy/Spain/etc): EUR (≈1.08 USD, or 1 USD ≈ 0.92 EUR)
        • Switzerland: CHF (≈1.12 USD)
        • Sweden: SEK (≈0.096 USD)
        • Norway: NOK (≈0.094 USD)
        • Denmark: DKK (≈0.15 USD)
        • Poland: PLN (≈0.25 USD)
        
        Asia:
        • Japan: JPY (≈0.0068 USD, or 1 USD ≈ 147 JPY)
        • China: CNY (≈0.14 USD, or 1 USD ≈ 7.2 CNY)
        • India: INR (≈0.012 USD, or 1 USD ≈ 83 INR)
        • South Korea: KRW (≈0.00077 USD, or 1 USD ≈ 1300 KRW)
        • Singapore: SGD (≈0.74 USD)
        • Hong Kong: HKD (≈0.13 USD)
        • Thailand: THB (≈0.029 USD)
        
        Middle East:
        • UAE/Dubai: AED (≈0.27 USD, or 1 USD ≈ 3.67 AED)
        • Saudi Arabia: SAR (≈0.27 USD)
        • Israel: ILS (≈0.28 USD)
        • Turkey: TRY (≈0.033 USD)
        
        Africa:
        • Nigeria: NGN (≈0.0013 USD)
        • South Africa: ZAR (≈0.053 USD, or 1 USD ≈ 19 ZAR)
        • Egypt: EGP (≈0.032 USD)
        
        Oceania:
        • Australia: AUD (≈0.66 USD, or 1 USD ≈ 1.51 AUD)
        • New Zealand: NZD (≈0.61 USD)
        
        ═══════════════════════════════════════
        EDGE CASES & COMMON ERRORS
        ═══════════════════════════════════════
        
        1. MULTIPLE CURRENCIES MENTIONED:
           Q: "What is Argentina's currency" [previous: Mexico]
           A: "Argentina's currency is the Argentine Peso (ARS)" [NOT Mexico!]
        
        2. TYPOS:
           Q: "Argentinian curvy"
           A: "I think you're asking about Argentina's currency! It's the Argentine Peso (ARS)."
        
        3. AMBIGUOUS AMOUNTS:
           Q: "How much is 100?"
           A: "Could you specify which currencies? For example: '100 USD to EUR' or '100 Mexican Pesos to Dollars'"
        
        4. IMPOSSIBLE CONVERSIONS:
           Q: "100 Bitcoin to USD"
           A: "I specialize in traditional currencies. Bitcoin (BTC) isn't in my database."
        
        5. VERY OLD/INVALID CURRENCIES:
           Q: "Puerto Rican Peso"
           A: "Puerto Rico now uses the US Dollar (USD). The Puerto Rican Peso was phased out in 1898."
        
        Remember: You're helpful, accurate, and action-oriented. Give direct answers!
        """
        }
        
        let session = LanguageModelSession(instructions: instructions)
        print("✅ Session Created Successfully")
        print("└─ Knowledge Base: 60+ countries loaded\n")
        
        return session
    }()
    
    /// Pre-warm the model to reduce latency on first request
    /// Following Apple's best practice from Chapter 6.1
    func prewarmModel() {
        print("🚨 DEBUG: prewarmModel() called")
        #if canImport(FoundationModels)
        print("✅ FoundationModels CAN be imported")
        print("📊 Model availability: \(model.availability)")
        
        guard isAvailable else {
            print("⚠️  Cannot prewarm: Model not available")
            print("📋 Reason: \(availabilityDescription)")
            return
        }
        
        print("🔥 Pre-warming model...")
        session.prewarm()
        print("✅ Model pre-warmed successfully")
        #else
        print("❌ FoundationModels CANNOT be imported - check your build settings")
        #endif
    }
    #endif

    /// True if the on-device model is available for use right now.
    var isAvailable: Bool {
        #if canImport(FoundationModels)
        return model.availability == .available
        #else
        return false
        #endif
    }

    /// Human-readable availability message for UI.
    var availabilityDescription: String {
        #if canImport(FoundationModels)
        switch model.availability {
        case .available:
            return "On-device model available"
        case .unavailable(.deviceNotEligible):
            return "Device not eligible for Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Enable Apple Intelligence in Settings to use on-device AI"
        case .unavailable(.modelNotReady):
            return "Model is downloading or not ready yet"
        case .unavailable(let other):
            return "Model unavailable: \(other)"
        }
        #else
        return "On-device model not supported by this build/OS"
        #endif
    }

    /// Optionally warm up the model/session at launch to reduce first-use latency.
    func warmUp() {
        #if canImport(FoundationModels)
        print("🔥 AIEngine: Starting Model Warm-Up")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("⏰ Warmup Time: \(Date())")
        print("📊 Model Availability: \(availabilityDescription)")
        
        guard model.availability == .available else {
            print("⚠️  Warm-up skipped - Model not available")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return
        }
        
        print("🚀 Sending warm-up request...")
        
        // A lightweight no-op prompt to initialize internals. Errors are ignored.
        Task {
            let startTime = Date()
            do {
                let response = try await session.respond(to: "Hello")
                let duration = Date().timeIntervalSince(startTime)
                print("✅ Warm-up Complete!")
                print("⏱️  Duration: \(String(format: "%.3f", duration))s")
                print("📝 Response: \"\(response.content)\"")
                print("💡 Model is now ready for fast responses")
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                print("⚠️  Warm-up failed (non-critical)")
                print("⏱️  Failed After: \(String(format: "%.3f", duration))s")
                print("🔴 Error: \(error.localizedDescription)")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
        #else
        print("⚠️  AIEngine: Warm-up skipped - FoundationModels not available\n")
        #endif
    }

    /// Parse a currency query using structured output with the on-device model
    func parseQuery(_ query: String, context: String? = nil) async -> CurrencyQueryParse? {
        #if canImport(FoundationModels)
        let startTime = Date()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🧠 AIEngine: LLM Query Parsing (Structured Output)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📝 Query: \"\(query)\"")
        if let ctx = context {
            print("💭 Context: \(ctx)")
        }
        
        guard isAvailable else {
            print("⚠️  Model Not Available - Cannot Parse")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return nil
        }
        
        // Use Prompt builder following Apple's best practices (Chapter 3.1)
        let prompt = Prompt {
            "Parse this currency-related query and extract the key information."
            ""
            "User query: \"\(query)\""
            
            if let ctx = context {
                ""
                "Context from conversation: \(ctx)"
            }
            
            """
        
        
        ═══════════════════════════════════════
        PARSING RULES (READ CAREFULLY!)
        ═══════════════════════════════════════
        
        1. EXPLICIT vs CONTEXT:
           • If query mentions SPECIFIC currency/country → Use THAT (ignore context)
           • If query has "that"/"it"/"this" → Use context
           • Example: "What is Argentina's currency" [context: MXN] → Answer about ARS, NOT MXN!
        
        2. INTENT CLASSIFICATION:
           • Conversion: Has amounts + currencies, or "convert", "how much is"
           • CurrencyInfo: Asks "what is X currency", "what currency does X use"
           • TravelAdvice: Mentions "travel", "trip", "visit"
           • RateInquiry: Asks "what's the rate", "exchange rate"
           • General: Other currency-related questions
        
        3. AMOUNT HANDLING:
           • From query: "100 USD" → amount=100
           • From context: "Recent mention: 1000 to 1500 USD" → amount=1000
           • No amount + conversion intent → amount=1 (default)
           • Ambiguous → isComplete=false
        
        4. CURRENCY EXTRACTION:
           • From codes: USD, EUR, MXN, JPY, etc.
           • From names: "dollars"=USD, "euros"=EUR, "peso"=MXN, "yen"=JPY
           • From countries: "Mexico"→MXN, "Argentina"→ARS, "Japan"→JPY
        
        5. EDGE CASES:
           • Multiple currencies mentioned: Use query's explicit mention over context
           • Typos: Be forgiving ("Argentinian curvy" → Argentina ARS)
           • Incomplete: Set isComplete=false, suggest what's needed in responseMessage
        
        ═══════════════════════════════════════
        OUTPUT FORMAT
        ═══════════════════════════════════════
        
        Extract and return:
        - amount: Double? (from query or context, null if not applicable)
        - fromCurrency: String? (ISO code: USD, MXN, EUR, etc.)
        - toCurrency: String? (ISO code)
        - intent: QueryIntent (Conversion, CurrencyInfo, TravelAdvice, RateInquiry, or General)
        - isComplete: Boolean (do we have enough info to answer fully?)
        - responseMessage: String (ACTION-ORIENTED response, give actual numbers/answers)
        
        ═══════════════════════════════════════
        EXAMPLES (LEARN FROM THESE!)
        ═══════════════════════════════════════
        
        Example 1 - New Currency Query:
        Query: "What is Argentina's currency"
        Context: "Recent mention: 1000 to 1500 USD, MXN"
        → amount: null
        → fromCurrency: null
        → toCurrency: null
        → intent: CurrencyInfo
        → isComplete: true
        → responseMessage: "Argentina's currency is the Argentine Peso (ARS)."
        
        Example 2 - Contextual Conversion:
        Query: "how much peso would that be"
        Context: "Recent mention: 1000 to 1500 USD"
        → amount: 1000
        → fromCurrency: USD
        → toCurrency: MXN
        → intent: Conversion
        → isComplete: true
        → responseMessage: "1000 USD is approximately 19,000 MXN. For 1500 USD, about 28,500 MXN."
        
        Example 3 - Direct Conversion:
        Query: "100 USD to EUR"
        Context: null
        → amount: 100
        → fromCurrency: USD
        → toCurrency: EUR
        → intent: Conversion
        → isComplete: true
        → responseMessage: "100 USD is approximately 92 EUR at current rates."
        
        Example 4 - Ambiguous Query:
        Query: "How much is 100?"
        Context: null
        → amount: 100
        → fromCurrency: null
        → toCurrency: null
        → intent: Conversion
        → isComplete: false
        → responseMessage: "Could you specify the currencies? For example: '100 USD to EUR' or '100 Mexican Pesos to Dollars'."
        
        Remember: Be smart, be accurate, prioritize query over context when explicit!
        """
        }  // Close Prompt builder
        
        // Log the actual prompt being sent
        print("📤 FULL PROMPT BEING SENT:")
        print("┌─────────────────────────────────────────────────┐")
        print(prompt)
        print("└─────────────────────────────────────────────────┘")
        print("")
        print("🚀 Sending structured parsing request...")
        
        do {
            // Use greedy sampling for better performance (Chapter 5.3.3 & 6.2)
            let response = try await session.respond(
                to: prompt,
                generating: CurrencyQueryParse.self,
                options: GenerationOptions(sampling: .greedy)
            )
            let duration = Date().timeIntervalSince(startTime)
            
            print("\n✅ Parsed Successfully!")
            print("⏱️  Parse Time: \(String(format: "%.2f", duration))s")
            print("📊 Parsed Data:")
            print("├─ Amount: \(response.content.amount?.description ?? "nil")")
            print("├─ From: \(response.content.fromCurrency ?? "nil")")
            print("├─ To: \(response.content.toCurrency ?? "nil")")
            print("├─ Intent: \(response.content.intent.rawValue)")
            print("├─ Complete: \(response.content.isComplete)")
            print("└─ Message: \"\(response.content.responseMessage)\"")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            return response.content
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("\n❌ Parsing Failed")
            print("⏱️  Failed After: \(String(format: "%.2f", duration))s")
            print("🔴 Error: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return nil
        }
        #else
        return nil
        #endif
    }
    
    /// Stream a response with real-time updates (for better UX)
    func streamResponse(to prompt: String, onUpdate: @escaping (String) -> Void) async {
        #if canImport(FoundationModels)
        let startTime = Date()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌊 AIEngine: Streaming LLM Response")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📝 Prompt: \"\(prompt.prefix(100))...\"")
        
        guard isAvailable else {
            print("⚠️  Model Not Available - Cannot Stream")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            onUpdate("⚠️ On-device AI not available. Please enable Apple Intelligence in Settings.")
            return
        }
        
        print("🚀 Starting stream...")
        
        do {
            var chunkCount = 0
            
            for try await snapshot in session.streamResponse(to: prompt) {
                // Extract text from snapshot
                let fullText = snapshot.content
                chunkCount += 1
                onUpdate(fullText)
                
                // Log progress every 10 chunks
                if chunkCount % 10 == 0 {
                    print("📦 \(chunkCount) chunks, \(fullText.count) chars")
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            print("\n✅ Stream Completed!")
            print("⏱️  Duration: \(String(format: "%.2f", duration))s")
            print("📦 Total Chunks: \(chunkCount)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("\n❌ Stream Failed")
            print("⏱️  Failed After: \(String(format: "%.2f", duration))s")
            print("🔴 Error: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            onUpdate("Sorry, I encountered an error while processing your request.")
        }
        #else
        onUpdate("On-device AI not supported on this platform.")
        #endif
    }

    /// Respond to a free-form prompt using the on-device model when available.
    func respond(to prompt: String) async -> String? {
        #if canImport(FoundationModels)
        let startTime = Date()
        
        // Log model availability details
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🤖 AIEngine: Starting LLM Request")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("⏰ Timestamp: \(ISO8601DateFormatter().string(from: startTime))")
        print("📊 Model Status: \(availabilityDescription)")
        print("✓ Model Available: \(isAvailable)")
        
        switch model.availability {
        case .available:
            print("🟢 Model State: READY")
        case .unavailable(let reason):
            print("🔴 Model State: UNAVAILABLE")
            print("❌ Reason: \(reason)")
        }
        
        print("\n📝 Request Details:")
        print("├─ Prompt Length: \(prompt.count) characters")
        print("└─ Prompt Preview: \(prompt.prefix(100))...")
        
        guard isAvailable else {
            print("\n⚠️  Model Not Available - Aborting Request")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return nil
        }
        
        print("\n🚀 Sending request to on-device LLM...")
        
        do {
            // Use greedy sampling for better performance
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(sampling: .greedy)
            )
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            print("\n✅ Response Received Successfully")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("⏱️  Response Time: \(String(format: "%.2f", duration))s")
            print("📊 Response Details:")
            print("├─ Content Length: \(response.content.count) characters")
            print("├─ Content: \"\(response.content)\"")
            print("└─ Content Preview: \(response.content.prefix(100))...")
            
            print("\n📈 Performance Metrics:")
            print("├─ Total Duration: \(String(format: "%.3f", duration))s")
            print("├─ Characters/Second: \(String(format: "%.1f", Double(response.content.count) / duration))")
            print("└─ Estimated Tokens: ~\(response.content.split(separator: " ").count * 4 / 3)")
            
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            return response.content
        } catch {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            print("\n❌ Error During LLM Request")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("⏱️  Failed After: \(String(format: "%.2f", duration))s")
            print("🔴 Error Type: \(type(of: error))")
            print("🔴 Error Description: \(error.localizedDescription)")
            print("🔴 Full Error: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            return nil
        }
        #else
        print("⚠️  AIEngine: FoundationModels not available in this build")
        return nil
        #endif
    }
}
