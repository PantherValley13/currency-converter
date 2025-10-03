//
//  CurrencyAITestView.swift
//  currency converter
//
//  Test view for the structured currency AI system
//

import SwiftUI

struct CurrencyAITestView: View {
    @State private var query: String = ""
    @State private var response: CurrencyResponse? = nil
    @State private var isProcessing: Bool = false
    @State private var streamingResponse: CurrencyResponse.PartiallyGenerated? = nil
    @State private var useStreaming: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Header
                HStack {
                    Circle()
                        .fill(CurrencyAIEngine.shared.isAvailable ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(CurrencyAIEngine.shared.availabilityDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ask about currency:")
                        .font(.headline)
                    
                    TextField("e.g., 100 USD to EUR", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.send)
                        .onSubmit { sendQuery() }
                    
                    HStack {
                        Toggle("Use Streaming", isOn: $useStreaming)
                            .font(.caption)
                        
                        Spacer()
                        
                        Button(action: { sendQuery() }) {
                            Label("Send", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(query.isEmpty || isProcessing)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Quick Test Buttons
                VStack(spacing: 8) {
                    Text("Quick Tests:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            QuickTestButton(title: "100 USD to EUR", query: "Convert 100 USD to EUR") { query = $0; sendQuery() }
                            QuickTestButton(title: "Japan Currency", query: "What is Japan's currency?") { query = $0; sendQuery() }
                            QuickTestButton(title: "Mexico Travel", query: "I'm traveling to Mexico, what should I know about money?") { query = $0; sendQuery() }
                            QuickTestButton(title: "Exchange Rate", query: "What's the USD to GBP exchange rate?") { query = $0; sendQuery() }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Response Section
                ScrollView {
                    if isProcessing {
                        ProgressView("Thinking...")
                            .padding()
                    } else if useStreaming, let streaming = streamingResponse {
                        StreamingResponseView(response: streaming)
                    } else if let response = response {
                        ResponseView(response: response)
                    } else {
                        EmptyStateView()
                    }
                }
            }
            .navigationTitle("Currency AI Test")
            .task {
                print("🎬 CurrencyAITestView: View appeared")
                CurrencyAIEngine.shared.prewarm()
            }
        }
    }
    
    private func sendQuery() {
        guard !query.isEmpty else { return }
        
        isProcessing = true
        response = nil
        streamingResponse = nil
        
        if useStreaming {
            Task {
                await CurrencyAIEngine.shared.streamQueryAnswer(query) { partial in
                    streamingResponse = partial
                }
                isProcessing = false
            }
        } else {
            Task {
                response = await CurrencyAIEngine.shared.answerQuery(query)
                isProcessing = false
            }
        }
    }
}

// MARK: - Response Views

struct ResponseView: View {
    let response: CurrencyResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(response.title)
                .font(.title2)
                .fontWeight(.bold)
            
            // Main Answer
            Text(response.answer)
                .font(.body)
            
            // Type Badge
            HStack {
                Image(systemName: iconForQueryType(response.queryType))
                Text(response.queryType.rawValue)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            Divider()
            
            // Conversion Details
            if let conversion = response.conversionDetails {
                ConversionDetailsView(details: conversion)
            }
            
            // Travel Advice
            if let travel = response.travelAdvice {
                TravelAdviceView(advice: travel)
            }
            
            // Currency Info
            if let info = response.currencyInfo {
                CurrencyInfoView(info: info)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding()
    }
    
    private func iconForQueryType(_ type: QueryType) -> String {
        switch type {
        case .conversion: return "arrow.left.arrow.right"
        case .currencyInfo: return "info.circle"
        case .travelAdvice: return "airplane"
        case .exchangeRate: return "chart.line.uptrend.xyaxis"
        case .general: return "questionmark.circle"
        }
    }
}

struct StreamingResponseView: View {
    let response: CurrencyResponse.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = response.title {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            if let answer = response.answer {
                Text(answer)
                    .font(.body)
            }
            
            if let queryType = response.queryType {
                HStack {
                    Image(systemName: "waveform")
                    Text(queryType.rawValue)
                    Text("(streaming...)")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding()
    }
}

struct ConversionDetailsView: View {
    let details: ConversionDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Conversion Details", systemImage: "dollarsign.circle.fill")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(details.amount, specifier: "%.2f") \(details.fromCurrency)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("converts to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("\(details.result, specifier: "%.2f") \(details.toCurrency)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            
            Text(details.explanation)
                .font(.callout)
            
            if let context = details.practicalContext {
                Label(context, systemImage: "lightbulb.fill")
                    .font(.callout)
                    .foregroundColor(.orange)
            }
            
            if let timing = details.timingAdvice {
                Label(timing, systemImage: "clock.fill")
                    .font(.callout)
                    .foregroundColor(.green)
            }
        }
    }
}

struct TravelAdviceView: View {
    let advice: TravelAdvice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Travel Tips for \(advice.destination)", systemImage: "airplane.circle.fill")
                .font(.headline)
            
            Text("Local Currency: \(advice.localCurrency)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Budget
            VStack(alignment: .leading, spacing: 4) {
                Text("\(advice.dailyBudget.level.rawValue) Budget")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(advice.dailyBudget.dailyAmount, specifier: "%.0f") per day")
                    .font(.title3)
                    .foregroundColor(.green)
                Text(advice.dailyBudget.includes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            
            // Tips
            ForEach(Array(advice.moneyTips.enumerated()), id: \.offset) { index, tip in
                MoneyTipRow(tip: tip)
            }
            
            // Warnings
            if !advice.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Important Warnings", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    ForEach(advice.warnings, id: \.self) { warning in
                        Text("• \(warning)")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

struct MoneyTipRow: View {
    let tip: MoneyTip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(tip.category.rawValue, systemImage: "star.fill")
                .font(.caption)
                .foregroundColor(.blue)
            Text(tip.advice)
                .font(.callout)
                .fontWeight(.medium)
            Text(tip.reasoning)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct CurrencyInfoView: View {
    let info: CurrencyInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Currency Information", systemImage: "info.circle.fill")
                .font(.headline)
            
            HStack {
                Text(info.name)
                    .font(.title3)
                    .fontWeight(.bold)
                Text("(\(info.code))")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text(info.symbol)
                    .font(.title)
            }
            
            Text("Used in: \(info.usedIn.joined(separator: ", "))")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Divider()
            
            ForEach(info.interestingFacts, id: \.self) { fact in
                HStack(alignment: .top) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text(fact)
                        .font(.callout)
                }
            }
            
            Text("Denominations: \(info.denominations)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Ask me anything about currency!")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Try conversions, currency info, or travel advice")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
}

struct QuickTestButton: View {
    let title: String
    let query: String
    let action: (String) -> Void
    
    var body: some View {
        Button(action: { action(query) }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
    }
}

#Preview {
    CurrencyAITestView()
}

