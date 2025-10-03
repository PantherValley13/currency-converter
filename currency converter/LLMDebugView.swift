//
//  LLMDebugView.swift
//  currency converter
//
//  Debug tool for Apple Foundation Models
//

import SwiftUI
import FoundationModels

struct LLMDebugView: View {
    @State private var debugLog: [String] = []
    @State private var isRunningTests = false
    @State private var testQuery = "What is Japan's currency?"
    @State private var lastResponse = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Status Section
                GroupBox("🔍 Model Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        StatusRow(
                            label: "Available",
                            value: CurrencyAIEngine.shared.isAvailable ? "✅ YES" : "❌ NO",
                            color: CurrencyAIEngine.shared.isAvailable ? .green : .red
                        )
                        
                        StatusRow(
                            label: "Description",
                            value: CurrencyAIEngine.shared.availabilityDescription,
                            color: .blue
                        )
                        
                        StatusRow(
                            label: "Raw Availability",
                            value: getAvailabilityRaw(),
                            color: .orange
                        )
                    }
                }
                .padding()
                
                // Test Query Section
                GroupBox("🧪 Test Query") {
                    VStack(spacing: 12) {
                        TextField("Enter test query", text: $testQuery)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: runTest) {
                            HStack {
                                if isRunningTests {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                }
                                Text(isRunningTests ? "Testing..." : "Run Test")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isRunningTests || !CurrencyAIEngine.shared.isAvailable)
                        
                        if !lastResponse.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Last Response:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ScrollView {
                                    Text(lastResponse)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(6)
                                }
                                .frame(maxHeight: 150)
                            }
                        }
                    }
                }
                .padding()
                
                // Quick Test Buttons
                GroupBox("⚡️ Quick Tests") {
                    VStack(spacing: 8) {
                        DebugTestButton(title: "Simple Conversion", query: "100 USD to EUR", action: {
                            testQuery = "100 USD to EUR"
                            runTest()
                        })
                        
                        DebugTestButton(title: "Currency Info", query: "What is Argentina's currency?", action: {
                            testQuery = "What is Argentina's currency?"
                            runTest()
                        })
                        
                        DebugTestButton(title: "Travel Advice", query: "I'm going to Tokyo with $2000", action: {
                            testQuery = "I'm going to Tokyo with $2000"
                            runTest()
                        })
                    }
                }
                .padding()
                
                // Debug Log
                GroupBox("📋 Debug Log") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            if debugLog.isEmpty {
                                Text("No logs yet. Run a test to see debug output.")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(Array(debugLog.enumerated()), id: \.offset) { index, log in
                                    Text(log)
                                        .font(.system(.caption, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 200)
                }
                .padding()
                
                Spacer()
                
                // Action Buttons
                HStack {
                    Button("Clear Log") {
                        debugLog.removeAll()
                        lastResponse = ""
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Prewarm Model") {
                        addLog("🔥 Prewarming model...")
                        CurrencyAIEngine.shared.prewarm()
                        addLog("✅ Prewarm initiated")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!CurrencyAIEngine.shared.isAvailable)
                }
                .padding()
            }
            .navigationTitle("🔬 LLM Debugger")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            runDiagnostics()
        }
    }
    
    private func runDiagnostics() {
        // Run comprehensive diagnostics
        let diagnosticLogs = DiagnosticEngine.shared.runFullDiagnostics()
        for log in diagnosticLogs {
            addLog(log)
        }
        
        // If model is available, test actual generation
        if CurrencyAIEngine.shared.isAvailable {
            addLog("")
            addLog("🧪 TESTING ACTUAL GENERATION...")
            addLog("├─ Sending test prompt to model...")
            
            DiagnosticEngine.shared.testSimpleGeneration { result in
                switch result {
                case .success(let response):
                    self.addLog("├─ ✅ SUCCESS!")
                    self.addLog("├─ Response: \"\(response)\"")
                    self.addLog("└─ Model is working correctly! 🎉")
                    
                case .failure(let error):
                    self.addLog("├─ ❌ FAILED!")
                    self.addLog("├─ Error: \(error.localizedDescription)")
                    self.addLog("└─ Model available but generation failed")
                }
                self.addLog("")
                self.addLog("═══════════════════════════════════════")
            }
        }
    }
    
    private func runTest() {
        guard !isRunningTests else { return }
        
        isRunningTests = true
        lastResponse = ""
        
        addLog("")
        addLog("🧪 TEST STARTED")
        addLog("📝 Query: \"\(testQuery)\"")
        addLog("⏱️  Start: \(Date())")
        
        Task {
            let startTime = Date()
            
            addLog("🚀 Sending query to CurrencyAIEngine...")
            
            guard let response = await CurrencyAIEngine.shared.answerQuery(testQuery) else {
                let duration = Date().timeIntervalSince(startTime)
                addLog("❌ No response received")
                addLog("⏱️  Duration: \(String(format: "%.2f", duration))s")
                await MainActor.run {
                    isRunningTests = false
                    lastResponse = "❌ No response received"
                }
                return
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            addLog("✅ Response received!")
            addLog("⏱️  Duration: \(String(format: "%.2f", duration))s")
            addLog("")
            addLog("📊 RESPONSE DETAILS:")
            addLog("├─ Title: \(response.title)")
            addLog("├─ Type: \(response.queryType.rawValue)")
            addLog("├─ Answer Length: \(response.answer.count) chars")
            
            if let conversion = response.conversionDetails {
                addLog("├─ Conversion:")
                addLog("│  ├─ Amount: \(conversion.amount)")
                addLog("│  ├─ From: \(conversion.fromCurrency)")
                addLog("│  ├─ To: \(conversion.toCurrency)")
                addLog("│  └─ Result: \(conversion.result)")
            }
            
            if let travel = response.travelAdvice {
                addLog("├─ Travel:")
                addLog("│  ├─ Destination: \(travel.destination)")
                addLog("│  └─ Currency: \(travel.localCurrency)")
            }
            
            addLog("└─ Full Answer:")
            addLog("   \(response.answer)")
            
            await MainActor.run {
                lastResponse = response.answer
                isRunningTests = false
            }
            
            addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
    }
    
    private func addLog(_ message: String) {
        DispatchQueue.main.async {
            debugLog.append(message)
            print(message) // Also print to Xcode console
        }
    }
    
    private func getAvailabilityRaw() -> String {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return "available"
        case .unavailable(.deviceNotEligible):
            return "unavailable(deviceNotEligible)"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "unavailable(appleIntelligenceNotEnabled)"
        case .unavailable(.modelNotReady):
            return "unavailable(modelNotReady)"
        case .unavailable(let reason):
            return "unavailable(\(reason))"
        }
    }
    
    private func getOSVersion() -> String {
        #if os(iOS)
        return "iOS \(UIDevice.current.systemVersion)"
        #elseif os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        return "Unknown"
        #endif
    }
    
    private func getDeviceModel() -> String {
        #if os(iOS)
        return UIDevice.current.model
        #elseif os(macOS)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
        #else
        return "Unknown"
        #endif
    }
}

// MARK: - Helper Views

struct StatusRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }
}

struct DebugTestButton: View {
    let title: String
    let query: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "bolt.fill")
                Text(title)
                Spacer()
                Text("\"\(query.prefix(20))...\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct LLMDebugView_Previews: PreviewProvider {
    static var previews: some View {
        LLMDebugView()
    }
}

