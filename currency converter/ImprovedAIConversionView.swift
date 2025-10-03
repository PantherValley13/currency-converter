//
//  ImprovedAIConversionView.swift
//  currency converter
//
//  Example view demonstrating Apple Foundation Models best practices
//

import SwiftUI

#if canImport(FoundationModels)
import FoundationModels

/// Example view showing streaming, structured outputs, and tool usage
struct ImprovedAIConversionView: View {
    let amount: Double
    let baseCurrency: String
    let targetCurrency: String
    let currentRate: Double?
    
    @Environment(\.dismiss) private var dismiss
    @State private var partialResponse: CurrencyConversionResponse.PartiallyGenerated?
    @State private var finalResponse: CurrencyConversionResponse?
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Availability indicator
                    availabilitySection
                    
                    // Request summary
                    requestSummaryCard
                    
                    // Response (streaming or complete)
                    responseSection
                    
                    Spacer()
                    
                    // Convert button
                    convertButton
                }
                .padding()
            }
            .navigationTitle("AI Currency Conversion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var availabilitySection: some View {
        HStack(spacing: 8) {
            Image(systemName: EnhancedAIEngine.shared.isAvailable ? "sparkles" : "sparkles.slash")
                .foregroundStyle(EnhancedAIEngine.shared.isAvailable ? .green : .secondary)
            
            Text(EnhancedAIEngine.shared.availabilityDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var requestSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conversion Request")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(formatNumber(amount)) \(baseCurrency)")
                        .font(.title3.weight(.semibold))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(targetCurrency)
                        .font(.title3.weight(.semibold))
                }
            }
            
            if let rate = currentRate {
                Divider()
                HStack {
                    Text("Current Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("1 \(baseCurrency) = \(String(format: "%.4f", rate)) \(targetCurrency)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    @ViewBuilder
    private var responseSection: some View {
        if let error = error {
            errorCard(error)
        } else if let final = finalResponse {
            completeResponseCard(final)
        } else if let partial = partialResponse {
            streamingResponseCard(partial)
        } else if !isLoading {
            placeholderCard
        } else {
            loadingCard
        }
    }
    
    private var placeholderCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Tap Convert to get AI-powered insights")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
        )
    }
    
    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Generating conversion...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
        )
    }
    
    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Error")
                    .font(.headline)
            }
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // Streaming response card - shows partial content as it arrives
    private func streamingResponseCard(_ partial: CurrencyConversionResponse.PartiallyGenerated) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Generating...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            // Show whatever fields have arrived
            if let toAmount = partial.toAmount {
                HStack {
                    Text("Converted Amount")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", toAmount))
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
            }
            
            if let rate = partial.exchangeRate {
                HStack {
                    Text("Exchange Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.4f", rate))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            
            if let explanation = partial.explanation {
                Divider()
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .animation(.easeInOut(duration: 0.3), value: partial.toAmount)
    }
    
    // Complete response card - shows all fields
    private func completeResponseCard(_ response: CurrencyConversionResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Conversion Complete")
                    .font(.headline)
            }
            
            // Result
            VStack(alignment: .leading, spacing: 8) {
                Text("Result")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.2f", response.toAmount))
                        .font(.system(size: 36, weight: .bold))
                        .monospacedDigit()
                    Text(response.toCurrency)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                detailRow(
                    label: "Exchange Rate",
                    value: String(format: "%.4f", response.exchangeRate)
                )
                
                if let context = response.context {
                    detailRow(
                        label: "Context",
                        value: context
                    )
                }
            }
            
            // Explanation
            if !response.explanation.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Explanation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(response.explanation)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.1),
                            Color(.secondarySystemBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
    
    private var convertButton: some View {
        Button {
            Task {
                await performConversion()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isLoading ? "Converting..." : "Convert with AI")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading || !EnhancedAIEngine.shared.isAvailable)
    }
    
    // MARK: - Actions
    
    private func performConversion() async {
        guard EnhancedAIEngine.shared.isAvailable else {
            error = "On-device AI is not available"
            return
        }
        
        isLoading = true
        error = nil
        partialResponse = nil
        finalResponse = nil
        
        do {
            // Use streaming for better UX
            let result = try await EnhancedAIEngine.shared.streamCurrencyConversion(
                amount: amount,
                from: baseCurrency,
                to: targetCurrency,
                currentRate: currentRate
            ) { partial in
                // Update UI with partial content as it arrives
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.partialResponse = partial
                    }
                }
            }
            
            // Set final result
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.finalResponse = result
                    self.partialResponse = nil
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Helpers
    
    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Preview

#Preview {
    ImprovedAIConversionView(
        amount: 100.0,
        baseCurrency: "USD",
        targetCurrency: "EUR",
        currentRate: 0.92
    )
}

#endif

