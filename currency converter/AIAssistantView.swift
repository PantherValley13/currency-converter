//
//  AIAssistantView.swift
//  currency converter
//
//  UI components for AI-powered features
//

import SwiftUI

// MARK: - AI Chat Interface
struct AIAssistantView: View {
    @ObservedObject private var assistant = AIAssistantManager.shared
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var currentTaskID: UUID? = nil
    @State private var showNewConversationAlert = false
    
    var onConversionRequest: (ConversionRequest) -> Void
    var onTravelRequest: ((String, Double) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("AI Assistant")
                    .font(.headline.weight(.semibold))
                Spacer()
                
                // New Conversation button
                Button {
                    if assistant.conversationHistory.isEmpty {
                        // Already empty, just show feedback
                        print("ℹ️  Conversation already empty")
                    } else {
                        // Show confirmation alert
                        showNewConversationAlert = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.bubble")
                        Text("New")
                }
                .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
                .help("Start a new conversation (clears context)")
                .disabled(assistant.conversationHistory.isEmpty)
                .opacity(assistant.conversationHistory.isEmpty ? 0.5 : 1.0)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            
            // Conversation
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Welcome message
                        if assistant.conversationHistory.isEmpty {
                            AIWelcomeView()
                                .padding()
                        }
                        
                        // Messages
                        ForEach(assistant.conversationHistory) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Processing indicator
                        if assistant.isProcessing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: assistant.conversationHistory.count) { _ in
                    if let lastMessage = assistant.conversationHistory.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input
            HStack(spacing: 12) {
                TextField("Ask me anything...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .focused($isInputFocused)
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: inputText.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.isEmpty ? Color(.secondaryLabel) : Color.blue)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || assistant.isProcessing) // Disabled when empty or processing
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .task {
            // Pre-warm the model on view appear for better performance
            print("🎬 AIAssistantView: View appeared - starting initialization")
            print("🔍 Checking model availability...")
            print("📊 Model Available: \(CurrencyAIEngine.shared.isAvailable)")
            print("📋 Status: \(CurrencyAIEngine.shared.availabilityDescription)")
            CurrencyAIEngine.shared.prewarm()
        }
        .alert("Start New Conversation?", isPresented: $showNewConversationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear & Start New", role: .destructive) {
                startNewConversation()
            }
        } message: {
            Text("This will clear all messages and reset the conversation context. This action cannot be undone.")
        }
    }
    
    private func sendMessage() {
        print("\n🚨 DEBUG: sendMessage() called!")
        print("📝 Input text: '\(inputText)'")
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ Input is empty, returning")
            return
        }
        
        // Sanitize and validate query
        let sanitizedQuery = sanitizeQuery(inputText)
        print("✅ Sanitized query: '\(sanitizedQuery)'")
        
        // Validate query length
        guard sanitizedQuery.count >= 2 else {
            print("⚠️  Query too short, ignoring")
            inputText = ""
            return
        }
        
        guard sanitizedQuery.count <= 500 else {
            let errorMessage = ConversationMessage(
                text: "Your message is too long. Please keep it under 500 characters.",
                isUser: false,
                timestamp: Date()
            )
            assistant.conversationHistory.append(errorMessage)
            inputText = ""
            return
        }
        
        let userMessage = ConversationMessage(
            text: sanitizedQuery,
            isUser: true,
            timestamp: Date()
        )
        assistant.conversationHistory.append(userMessage)
        
        let query = sanitizedQuery
        inputText = ""
        
        print("\n╔════════════════════════════════════════════════════════╗")
        print("║          AIAssistantView: New User Query              ║")
        print("╚════════════════════════════════════════════════════════╝")
        print("📝 Query: \"\(query)\"")
        print("📏 Length: \(query.count) characters")
        print("⏰ Timestamp: \(Date())")
        
        let token = UUID()
        currentTaskID = token
        print("🔖 Task ID: \(token.uuidString.prefix(8))...")
        
        // Check for travel intent (still parse it to trigger the action, but let LLM respond)
        let travelIntent = parseTravelIntent(query)
        if let travel = travelIntent {
            print("\n✈️  Travel Intent Detected:")
            print("├─ Destination: \(travel.destination)")
            print("├─ Budget: \(travel.budget)")
            print("└─ Action: Triggering onTravelRequest()")
            // Trigger the travel request action in the background
            onTravelRequest?(travel.destination, travel.budget)
        }
        
        Task {
            print("\n🔍 Processing Query with Structured AI...")
            
            // Check model availability
            guard CurrencyAIEngine.shared.isAvailable else {
                print("❌ Model not available: \(CurrencyAIEngine.shared.availabilityDescription)")
                let errorMsg = ConversationMessage(
                    text: "⚠️ AI features require Apple Intelligence\n\n\(CurrencyAIEngine.shared.availabilityDescription)\n\nPlease check:\n• iOS 18.1+ or macOS 15.1+\n• Apple Intelligence enabled in Settings\n• Compatible device (iPhone 15 Pro or later, M1+ Mac)",
                    isUser: false,
                    timestamp: Date()
                )
                assistant.conversationHistory.append(errorMsg)
                print("╚════════════════════════════════════════════════════════╝\n")
            return
        }
        
            // Extract recent conversation history for context
            let history = extractConversationHistory()
            print("💭 Passing \(history.count) previous exchanges for context")
            
            // Get structured response from AI with conversation context
            guard let response = await CurrencyAIEngine.shared.answerQuery(query, conversationHistory: history) else {
                guard currentTaskID == token else { return }
                
                print("❌ Failed to get response")
                
                // Provide helpful error message based on query length and context
                let queryLength = query.count
                let contextSize = history.count
                
                var errorText = "⚠️ I couldn't process that request.\n\n"
                
                if queryLength > 200 && contextSize > 0 {
                    errorText += "Your question is quite long and we have conversation history.\n\nTry:\n• Asking a shorter, simpler question\n• Click 'New' to clear conversation history"
                } else if queryLength > 200 {
                    errorText += "Your question is quite long.\n\nTry:\n• Breaking it into smaller questions\n• Asking more directly"
                } else if contextSize >= 5 {
                    errorText += "We've been chatting for a while.\n\nTry:\n• Click 'New' to start fresh\n• Ask your question again"
                } else {
                    errorText += "This might be due to:\n• Complex question requiring detailed response\n• Temporary processing issue\n\nTry:\n• Rephrasing your question\n• Making it more specific"
                }
                
                let errorMsg = ConversationMessage(
                    text: errorText,
                    isUser: false,
                    timestamp: Date()
                )
                assistant.conversationHistory.append(errorMsg)
                print("╚════════════════════════════════════════════════════════╝\n")
            return
        }
        
            guard currentTaskID == token else {
                print("⚠️  Task cancelled")
            return
        }
        
            print("\n✅ Got Structured Response:")
            print("├─ Title: \(response.title)")
            print("├─ Type: \(response.queryType.rawValue)")
            print("└─ Answer: \(response.answer.prefix(100))...")
            
            // Add the answer to conversation
                    let aiMessage = ConversationMessage(
                text: response.answer,
                        isUser: false,
                        timestamp: Date()
                    )
                    assistant.conversationHistory.append(aiMessage)
            print("💬 Added to conversation")
            
            // Handle conversion requests
            if let conversion = response.conversionDetails {
                print("\n🔔 Conversion Detected:")
                print("├─ \(conversion.amount) \(conversion.fromCurrency) → \(conversion.toCurrency)")
                print("├─ Result: \(conversion.result)")
                print("└─ Triggering conversion action...")
                
                let request = ConversionRequest(
                    amount: conversion.amount,
                    baseCurrency: conversion.fromCurrency,
                    targetCurrency: conversion.toCurrency,
                    userQuery: query,
                    responseMessage: response.answer
                )
                onConversionRequest(request)
            }
            
            // Handle travel advice
            if let travel = response.travelAdvice {
                print("\n✈️  Travel Advice Detected:")
                print("├─ Destination: \(travel.destination)")
                print("├─ Currency: \(travel.localCurrency)")
                print("└─ Daily Budget: \(travel.dailyBudget.dailyAmount)")
                
                // Could trigger travel-specific actions here
                onTravelRequest?(travel.destination, travel.dailyBudget.dailyAmount)
            }
            
            print("╚════════════════════════════════════════════════════════╝\n")
        }
    }
    
    /// Starts a new conversation by clearing all context and history
    private func startNewConversation() {
        print("\n🔄 STARTING NEW CONVERSATION")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Current history: \(assistant.conversationHistory.count) messages")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            // Clear all conversation history
            assistant.conversationHistory.removeAll()
            
            // Reset any pending tasks
            currentTaskID = nil
            
            // Clear input
            inputText = ""
        }
        
        // **CRITICAL FIX:** Reset the LLM session to clear any bad state from token limit errors
        CurrencyAIEngine.shared.resetSession()
        
        print("✅ Conversation reset")
        print("📊 New history: \(assistant.conversationHistory.count) messages")
        print("💭 Context cleared - fresh start!")
        print("🔄 LLM session reset - ready for new queries")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    /// Extracts recent conversation for context memory (last 7 exchanges - extended memory)
    private func extractConversationHistory() -> [(userQuery: String, aiResponse: String)] {
        var history: [(userQuery: String, aiResponse: String)] = []
        
        // Get last 14 messages (up to 7 exchanges)
        let recentMessages = assistant.conversationHistory.suffix(14)
        
        var pendingUserQuery: String?
        
        for message in recentMessages {
            if message.isUser {
                // Store user query, waiting for AI response
                pendingUserQuery = message.text
            } else if let userQuery = pendingUserQuery {
                // Pair found - add to history
                // Keep responses short to avoid token limits (truncate if needed)
                let shortResponse = message.text.count > 150 ? 
                    String(message.text.prefix(150)) + "..." : message.text
                
                history.append((userQuery: userQuery, aiResponse: shortResponse))
                pendingUserQuery = nil
                
                // Limit to last 7 exchanges (extended memory for complex conversations)
                if history.count >= 7 {
                    break
                }
            }
        }
        
        return Array(history.prefix(7))
    }
    
    /// Extracts recently mentioned currencies and amounts from conversation history
    /// Returns a rich context string with amounts and currencies for smarter parsing
    /// Example: "$1,000 to $1,500 USD" → "amounts: 1000-1500, currency: USD"
    private func extractRecentCurrencyContext() -> String? {
        // Look at last 3 AI messages (most recent context)
        let recentMessages = assistant.conversationHistory.suffix(6).filter { !$0.isUser }
        
        // Common currency codes to search for
        let knownCurrencies = [
            "USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "BRL", 
            "ZAR", "SEK", "NGN", "MXN", "KRW", "THB", "AED", "SAR"
        ]
        
        // Search backwards through conversation for currency mentions with amounts
        for message in recentMessages.reversed() {
            let text = message.text
            
            // Check for currency codes
            for currency in knownCurrencies {
                if text.uppercased().contains(currency) {
                    // Try to extract amounts near this currency
                    let amounts = extractAmountsFromText(text)
                    
                    if !amounts.isEmpty {
                        let contextString = "Recent mention: \(amounts.joined(separator: " to ")) \(currency)"
                        print("AIAssistantView: Found rich context -> \(contextString)")
                        return contextString
            } else {
                        print("AIAssistantView: Found context currency -> \(currency)")
                        return "Recent currency: \(currency)"
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Handles parsed intent from LLM with streaming support
    /// Sanitizes user query to prevent issues
    private func sanitizeQuery(_ query: String) -> String {
        var sanitized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove excessive whitespace
        sanitized = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove control characters except newlines (which we'll then replace with spaces)
        sanitized = sanitized.components(separatedBy: .controlCharacters).joined(separator: " ")
        
        // Normalize common typos/variations
        sanitized = sanitized.replacingOccurrences(of: "curency", with: "currency", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "currancy", with: "currency", options: .caseInsensitive)
        
        return sanitized
    }
    
    /// Extracts dollar/number amounts from text like "$1,000" or "1500 USD"
    private func extractAmountsFromText(_ text: String) -> [String] {
        var amounts: [String] = []
        
        // Pattern 1: $1,000 or $1000
        let dollarPattern = #"\$[\d,]+"#
        if let regex = try? NSRegularExpression(pattern: dollarPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let amount = String(text[range]).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                    amounts.append(amount)
                }
            }
        }
        
        // Pattern 2: 1000 USD or 1,500 EUR (number before currency code)
        let numberPattern = #"\d[\d,]*\s*(?:USD|EUR|GBP|MXN|JPY)"#
        if let regex = try? NSRegularExpression(pattern: numberPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let amount = String(text[range]).components(separatedBy: CharacterSet.letters).first?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "")
                    if let amt = amount, !amt.isEmpty {
                        amounts.append(amt)
                    }
                }
            }
        }
        
        return amounts
    }
    
    private func parseTravelIntent(_ query: String) -> (destination: String, budget: Double)? {
        let lower = query.lowercased()
        guard lower.contains("travel") || lower.contains("travel advice") else { return nil }
        // Extract first number as budget (default to 1000 if missing)
        let digits = query.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.joined()
        let budget = Double(digits) ?? 1000
        // Determine destination from common patterns: "travel to X", "about X", "for X"
        var destination = ""
        let stopWords: Set<String> = ["with", "for", "on", "in", "using", "about", "budget", "currency", "money"]
        func extractFollowing(after needle: String) -> String? {
            if let r = lower.range(of: needle) {
                let rest = query[r.upperBound...]
                var parts: [String] = []
                for word in rest.split(separator: " ") {
                    let w = word.trimmingCharacters(in: .punctuationCharacters)
                    if stopWords.contains(w.lowercased()) { break }
                    parts.append(String(w))
                }
                let joined = parts.joined(separator: " ")
                return joined.isEmpty ? nil : joined
            }
            return nil
        }
        destination = extractFollowing(after: "travel to ") ?? extractFollowing(after: "about ") ?? extractFollowing(after: "for ") ?? ""
        destination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !destination.isEmpty else { return nil }
        return (destination, budget)
    }
    
    private func detectCountryCurrencyQuery(_ query: String) -> (country: String, code: String, name: String)? {
        let lower = query.lowercased()
        guard lower.contains("currency of") || lower.contains("what is the currency") || 
              lower.contains("currency in") || lower.contains("what currency") else { return nil }
        
        // Comprehensive country-to-currency map
        let mapping: [String: (code: String, name: String)] = [
            // Americas
            "united states": ("USD", "US Dollar"),
            "usa": ("USD", "US Dollar"),
            "america": ("USD", "US Dollar"),
            "puerto rico": ("USD", "US Dollar"), // US Territory
            "canada": ("CAD", "Canadian Dollar"),
            "mexico": ("MXN", "Mexican Peso"),
            "brazil": ("BRL", "Brazilian Real"),
            "argentina": ("ARS", "Argentine Peso"),
            "chile": ("CLP", "Chilean Peso"),
            "colombia": ("COP", "Colombian Peso"),
            
            // Europe
            "united kingdom": ("GBP", "British Pound"),
            "uk": ("GBP", "British Pound"),
            "britain": ("GBP", "British Pound"),
            "england": ("GBP", "British Pound"),
            "european union": ("EUR", "Euro"),
            "eurozone": ("EUR", "Euro"),
            "germany": ("EUR", "Euro"),
            "france": ("EUR", "Euro"),
            "italy": ("EUR", "Euro"),
            "spain": ("EUR", "Euro"),
            "portugal": ("EUR", "Euro"),
            "netherlands": ("EUR", "Euro"),
            "belgium": ("EUR", "Euro"),
            "austria": ("EUR", "Euro"),
            "greece": ("EUR", "Euro"),
            "ireland": ("EUR", "Euro"),
            "switzerland": ("CHF", "Swiss Franc"),
            "sweden": ("SEK", "Swedish Krona"),
            "norway": ("NOK", "Norwegian Krone"),
            "denmark": ("DKK", "Danish Krone"),
            "poland": ("PLN", "Polish Zloty"),
            "czech": ("CZK", "Czech Koruna"),
            "russia": ("RUB", "Russian Ruble"),
            
            // Asia
            "japan": ("JPY", "Japanese Yen"),
            "china": ("CNY", "Chinese Yuan"),
            "india": ("INR", "Indian Rupee"),
            "south korea": ("KRW", "South Korean Won"),
            "korea": ("KRW", "South Korean Won"),
            "singapore": ("SGD", "Singapore Dollar"),
            "hong kong": ("HKD", "Hong Kong Dollar"),
            "thailand": ("THB", "Thai Baht"),
            "malaysia": ("MYR", "Malaysian Ringgit"),
            "indonesia": ("IDR", "Indonesian Rupiah"),
            "philippines": ("PHP", "Philippine Peso"),
            "vietnam": ("VND", "Vietnamese Dong"),
            "taiwan": ("TWD", "New Taiwan Dollar"),
            "pakistan": ("PKR", "Pakistani Rupee"),
            "bangladesh": ("BDT", "Bangladeshi Taka"),
            
            // Middle East
            "saudi arabia": ("SAR", "Saudi Riyal"),
            "saudi": ("SAR", "Saudi Riyal"),
            "uae": ("AED", "UAE Dirham"),
            "dubai": ("AED", "UAE Dirham"),
            "emirates": ("AED", "UAE Dirham"),
            "israel": ("ILS", "Israeli Shekel"),
            "turkey": ("TRY", "Turkish Lira"),
            "qatar": ("QAR", "Qatari Riyal"),
            "kuwait": ("KWD", "Kuwaiti Dinar"),
            
            // Africa
            "nigeria": ("NGN", "Nigerian Naira"),
            "south africa": ("ZAR", "South African Rand"),
            "egypt": ("EGP", "Egyptian Pound"),
            "kenya": ("KES", "Kenyan Shilling"),
            "ghana": ("GHS", "Ghanaian Cedi"),
            "morocco": ("MAD", "Moroccan Dirham"),
            
            // Oceania
            "australia": ("AUD", "Australian Dollar"),
            "new zealand": ("NZD", "New Zealand Dollar")
        ]
        
        // Find longest matching country name (to handle "south korea" vs "korea")
        var bestMatch: (country: String, code: String, name: String)?
        var longestMatchLength = 0
        
        for (country, info) in mapping {
            if lower.contains(country) && country.count > longestMatchLength {
                longestMatchLength = country.count
                bestMatch = (country.capitalized, info.code, info.name)
            }
        }
        
        return bestMatch
    }
    
    private func buildAssistantPrompt(for query: String) -> String {
        // Give the LLM clear guidance for answering currency questions
        return """
        Answer this currency-related question directly and helpfully:
        
        "\(query)"
        
        Provide a clear, friendly answer in 1-3 sentences. Use ISO currency codes (USD, EUR, MXN, etc.).
        """
    }
    
    private func buildConversionPrompt(for request: ConversionRequest, originalQuery: String) -> String {
        // Direct, clear instruction for the LLM
        return """
        The user wants to convert \(request.amount) \(request.baseCurrency) to \(request.targetCurrency).
        
        Respond with a brief, friendly acknowledgment (1-2 sentences). The app will show the live exchange rate and result immediately after your message.
        """
    }
}

struct MessageBubble: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(message.isUser ? Color.blue : Color(.tertiarySystemBackground))
                    )
                    .foregroundStyle(message.isUser ? .white : .primary)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

struct AIWelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("AI Currency Assistant")
                .font(.title2.weight(.bold))
            
            Text("I can help you with:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "dollarsign.circle", text: "Natural language conversions")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Rate trend predictions")
                FeatureRow(icon: "airplane", text: "Travel budget insights")
                FeatureRow(icon: "bell.badge", text: "Smart alert recommendations")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Smart Suggestions Panel
struct SmartSuggestionsView: View {
    @ObservedObject private var assistant = AIAssistantManager.shared
    var onSuggestionTapped: (SmartSuggestion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Smart Suggestions")
                    .font(.headline.weight(.semibold))
                Spacer()
            }
            
            if assistant.smartSuggestions.isEmpty {
                Text("Suggestions will appear based on your usage patterns")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(assistant.smartSuggestions) { suggestion in
                    SuggestionCard(suggestion: suggestion) {
                        onSuggestionTapped(suggestion)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground).opacity(0.8),
                            Color(.tertiarySystemBackground).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

struct SuggestionCard: View {
    let suggestion: SmartSuggestion
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(Int(suggestion.confidence * 100))%")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Travel Insights View
struct TravelInsightsView: View {
    let insight: TravelInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "airplane.departure")
                    .foregroundStyle(.blue)
                Text("Travel to \(insight.destination)")
                    .font(.headline.weight(.semibold))
                Spacer()
            }
            
            // Budget overview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Your Budget:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(formatCurrency(insight.budgetInLocal)) \(insight.localCurrency)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                }
                
                HStack {
                    Text("Daily Budget:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(formatCurrency(insight.purchasingPower.dailyBudget)) \(insight.localCurrency)")
                        .font(.subheadline.weight(.semibold))
                }
                
                HStack {
                    Text("Estimated Duration:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(insight.purchasingPower.estimatedDays) days")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
            
            // Purchasing power indicator
            PurchasingPowerBar(power: insight.purchasingPower)
            
            // Recommendations
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommendations")
                    .font(.subheadline.weight(.semibold))
                
                ForEach(insight.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(recommendation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Best time to exchange
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                Text(insight.bestTimeToExchange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.1))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground).opacity(0.8),
                            Color(.tertiarySystemBackground).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

struct PurchasingPowerBar: View {
    let power: PurchasingPower
    
    var color: Color {
        switch power.category {
        case .excellent: return .green
        case .good: return .blue
        case .moderate: return .orange
        case .limited: return .red
        }
    }
    
    var categoryText: String {
        switch power.category {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .moderate: return "Moderate"
        case .limited: return "Limited"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Purchasing Power:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(categoryText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(width: geometry.size.width * powerPercentage)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var powerPercentage: Double {
        switch power.category {
        case .excellent: return 1.0
        case .good: return 0.75
        case .moderate: return 0.5
        case .limited: return 0.25
        }
    }
}

// MARK: - Rate Trend Prediction View
struct RateTrendView: View {
    let prediction: RateTrendPrediction
    let baseCurrency: String
    let targetCurrency: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Trend icon
            ZStack {
                Circle()
                    .fill(trendColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: trendIcon)
                    .font(.title3)
                    .foregroundStyle(trendColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(baseCurrency) → \(targetCurrency)")
                        .font(.subheadline.weight(.semibold))
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(trendText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(trendColor)
                }
                
                Text(prediction.recommendation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    Text("Confidence:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ProgressView(value: prediction.confidence)
                        .frame(width: 60)
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(trendColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(trendColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var trendColor: Color {
        switch prediction.direction {
        case .rising: return .green
        case .falling: return .red
        case .stable: return .blue
        }
    }
    
    private var trendIcon: String {
        switch prediction.direction {
        case .rising: return "arrow.up.right.circle.fill"
        case .falling: return "arrow.down.right.circle.fill"
        case .stable: return "equal.circle.fill"
        }
    }
    
    private var trendText: String {
        switch prediction.direction {
        case .rising: return "Rising"
        case .falling: return "Falling"
        case .stable: return "Stable"
        }
    }
}

// MARK: - Alert Recommendations View
struct AlertRecommendationsView: View {
    let recommendations: [AlertRecommendation]
    var onCreateAlert: (AlertRecommendation) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.orange)
                Text("Recommended Alerts")
                    .font(.headline.weight(.semibold))
                Spacer()
            }
            
            if recommendations.isEmpty {
                Text("No alert recommendations available yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(recommendations) { recommendation in
                    AlertRecommendationCard(recommendation: recommendation) {
                        onCreateAlert(recommendation)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground).opacity(0.8),
                            Color(.tertiarySystemBackground).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

struct AlertRecommendationCard: View {
    let recommendation: AlertRecommendation
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendation.type == .above ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(recommendation.type == .above ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Alert at \(String(format: "%.4f", recommendation.threshold))")
                    .font(.subheadline.weight(.semibold))
                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Add") {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

#Preview {
    AIAssistantView { request in
        print("Preview: Received conversion request -> \(request)")
    }
}

