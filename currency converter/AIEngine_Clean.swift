// AIEngine_Clean.swift
// Clean rebuild of Foundation Models integration following Apple's best practices
// Based on: Foundation Models Code-Along Instructions

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Simplified, clean AIEngine following Apple's exact patterns
final class AIEngine_Clean {
    static let shared = AIEngine_Clean()
    
    private init() {
        print("🔧 AIEngine_Clean: Initializing")
    }
    
    #if canImport(FoundationModels)
    // MARK: - Foundation Models Components
    
    private let model = SystemLanguageModel.default
    
    // Lazy session with instructions (Chapter 1.2)
    private lazy var session: LanguageModelSession = {
        print("📝 Creating LanguageModelSession with instructions")
        
        let instructions = """
        You are a helpful currency assistant.
        
        Your job is to:
        1. Answer questions about currencies
        2. Help with currency conversions
        3. Provide exchange rate information
        
        Rules:
        - Be concise (1-2 sentences)
        - Use ISO currency codes (USD, EUR, JPY, etc.)
        - Give direct answers, not explanations
        - For conversions, provide approximate values
        
        Examples:
        Q: "What is Japan's currency?"
        A: "Japan's currency is the Japanese Yen (JPY)."
        
        Q: "100 USD to EUR"
        A: "100 USD is approximately 92 EUR."
        """
        
        return LanguageModelSession(instructions: instructions)
    }()
    
    // MARK: - Availability Check (Chapter 1.3)
    
    var isAvailable: Bool {
        let available = model.availability == .available
        print("🔍 Model availability check: \(available)")
        return available
    }
    
    var availabilityDescription: String {
        switch model.availability {
        case .available:
            return "Model is ready"
        case .unavailable(.deviceNotEligible):
            return "Device not eligible for Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Enable Apple Intelligence in Settings"
        case .unavailable(.modelNotReady):
            return "Model is still downloading"
        case .unavailable(let other):
            return "Unavailable: \(other)"
        }
    }
    
    // MARK: - Pre-warming (Chapter 6.1)
    
    func prewarm() {
        print("🔥 Pre-warming model...")
        guard isAvailable else {
            print("⚠️ Cannot prewarm: \(availabilityDescription)")
            return
        }
        session.prewarm()
        print("✅ Pre-warming complete")
    }
    
    // MARK: - Basic Text Generation (Chapter 1.1)
    
    func respond(to query: String) async -> String? {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🤖 AIEngine_Clean: Text Generation")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📝 Query: \"\(query)\"")
        
        guard isAvailable else {
            print("❌ Model not available: \(availabilityDescription)")
            return nil
        }
        
        do {
            print("🚀 Sending request...")
            let response = try await session.respond(to: query)
            let text = response.content
            print("✅ Response received: \(text.count) characters")
            print("💬 Content: \"\(text)\"")
            return text
        } catch {
            print("❌ Error: \(error)")
            return nil
        }
    }
    
    // MARK: - Structured Output (Chapter 2.1)
    
    func parseQuery(_ query: String) async -> SimpleParse? {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🧠 AIEngine_Clean: Structured Parse")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📝 Query: \"\(query)\"")
        
        guard isAvailable else {
            print("❌ Model not available: \(availabilityDescription)")
            return nil
        }
        
        let prompt = "Parse this currency query: \"\(query)\""
        
        do {
            print("🚀 Requesting structured output...")
            let response = try await session.respond(
                to: prompt,
                generating: SimpleParse.self,
                options: GenerationOptions(sampling: .greedy)
            )
            let parsed = response.content
            print("✅ Parsed successfully!")
            print("📊 Intent: \(parsed.intent)")
            print("💬 Message: \"\(parsed.message)\"")
            return parsed
        } catch {
            print("❌ Parse error: \(error)")
            return nil
        }
    }
    
    #else
    // MARK: - Unavailable Stubs
    
    var isAvailable: Bool { false }
    var availabilityDescription: String { "FoundationModels not available on this platform" }
    func prewarm() { print("⚠️ FoundationModels not available") }
    func respond(to query: String) async -> String? { nil }
    func parseQuery(_ query: String) async -> SimpleParse? { nil }
    
    #endif
}

// MARK: - Simple Models (Chapter 2.1)

#if canImport(FoundationModels)
import FoundationModels

@Generable
struct SimpleParse {
    @Guide(description: "The user's intent: conversion, info, or general")
    let intent: String
    
    @Guide(description: "A helpful message to show the user")
    let message: String
    
    @Guide(description: "The amount to convert, if any")
    let amount: Double?
    
    @Guide(description: "The source currency code (e.g., USD)")
    let fromCurrency: String?
    
    @Guide(description: "The target currency code (e.g., EUR)")
    let toCurrency: String?
}

#endif

