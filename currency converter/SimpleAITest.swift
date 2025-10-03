// SimpleAITest.swift
// Minimal test view to verify Foundation Models is working

import SwiftUI

struct SimpleAITest: View {
    @State private var input: String = ""
    @State private var output: String = "No response yet"
    @State private var isProcessing: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Foundation Models Test")
                .font(.title)
                .bold()
            
            // Availability status
            HStack {
                Circle()
                    .fill(AIEngine_Clean.shared.isAvailable ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(AIEngine_Clean.shared.availabilityDescription)
                    .font(.caption)
            }
            
            // Input
            TextField("Ask about currency...", text: $input)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            // Buttons
            HStack(spacing: 15) {
                Button("Test Basic Response") {
                    testBasicResponse()
                }
                .buttonStyle(.borderedProminent)
                .disabled(input.isEmpty || isProcessing)
                
                Button("Test Structured Parse") {
                    testStructuredParse()
                }
                .buttonStyle(.bordered)
                .disabled(input.isEmpty || isProcessing)
            }
            
            // Output
            ScrollView {
                Text(output)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .padding()
            
            if isProcessing {
                ProgressView()
            }
        }
        .padding()
        .task {
            // Pre-warm on appear
            print("🎬 SimpleAITest: View appeared")
            AIEngine_Clean.shared.prewarm()
        }
    }
    
    private func testBasicResponse() {
        isProcessing = true
        output = "Processing..."
        
        Task {
            if let response = await AIEngine_Clean.shared.respond(to: input) {
                output = "✅ Success!\n\n\(response)"
            } else {
                output = "❌ Failed\n\nModel not available or error occurred.\n\nStatus: \(AIEngine_Clean.shared.availabilityDescription)"
            }
            isProcessing = false
        }
    }
    
    private func testStructuredParse() {
        isProcessing = true
        output = "Processing..."
        
        Task {
            if let parsed = await AIEngine_Clean.shared.parseQuery(input) {
                output = """
                ✅ Structured Parse Success!
                
                Intent: \(parsed.intent)
                Message: \(parsed.message)
                Amount: \(parsed.amount?.description ?? "none")
                From: \(parsed.fromCurrency ?? "none")
                To: \(parsed.toCurrency ?? "none")
                """
            } else {
                output = "❌ Parse Failed\n\nModel not available or error occurred.\n\nStatus: \(AIEngine_Clean.shared.availabilityDescription)"
            }
            isProcessing = false
        }
    }
}

#Preview {
    SimpleAITest()
}

