//
//  DiagnosticEngine.swift
//  currency converter
//
//  Ultra-detailed diagnostics for Foundation Models
//

import Foundation
import FoundationModels
#if canImport(UIKit)
import UIKit
#endif

class DiagnosticEngine {
    static let shared = DiagnosticEngine()
    
    private init() {}
    
    func runFullDiagnostics() -> [String] {
        var logs: [String] = []
        
        print("\n\n═══════════════════════════════════════")
        print("🔬 FULL LLM DIAGNOSTICS - STARTING")
        print("═══════════════════════════════════════\n")
        
        logs.append("═══════════════════════════════════════")
        logs.append("🔬 FULL LLM DIAGNOSTICS")
        logs.append("═══════════════════════════════════════")
        logs.append("")
        
        // 1. System Info
        logs.append("📱 SYSTEM INFORMATION:")
        logs.append("├─ OS: \(getOSVersion())")
        logs.append("├─ Device: \(getDeviceModel())")
        logs.append("├─ Timestamp: \(Date())")
        logs.append("└─ Build: \(getBuildInfo())")
        logs.append("")
        
        // 2. Foundation Models Framework
        logs.append("📦 FOUNDATION MODELS FRAMEWORK:")
        #if canImport(FoundationModels)
        logs.append("├─ Import: ✅ Available")
        #else
        logs.append("├─ Import: ❌ NOT Available")
        logs.append("└─ CRITICAL: FoundationModels framework not found!")
        return logs
        #endif
        
        // 3. SystemLanguageModel Check
        logs.append("└─ SystemLanguageModel: Checking...")
        let model = SystemLanguageModel.default
        logs.append("")
        
        // 4. Availability Check
        logs.append("🤖 MODEL AVAILABILITY:")
        logs.append("├─ Checking SystemLanguageModel.default.availability...")
        
        switch model.availability {
        case .available:
            logs.append("├─ Status: ✅ AVAILABLE")
            logs.append("└─ Raw: .available")
            
        case .unavailable(.deviceNotEligible):
            logs.append("├─ Status: ❌ UNAVAILABLE")
            logs.append("├─ Reason: Device Not Eligible")
            logs.append("├─ Required: iPhone 15 Pro+ or M1+ Mac")
            logs.append("└─ Your device doesn't support Apple Intelligence")
            
        case .unavailable(.appleIntelligenceNotEnabled):
            logs.append("├─ Status: ❌ UNAVAILABLE")
            logs.append("├─ Reason: Apple Intelligence Not Enabled")
            logs.append("├─ Fix: Settings → Apple Intelligence & Siri")
            logs.append("└─ Enable Apple Intelligence")
            
        case .unavailable(.modelNotReady):
            logs.append("├─ Status: ⏳ DOWNLOADING")
            logs.append("├─ Reason: Model Not Ready")
            logs.append("├─ Action: Model is downloading")
            logs.append("└─ Wait 5-10 minutes, check internet connection")
            
        case .unavailable(let reason):
            logs.append("├─ Status: ❌ UNAVAILABLE")
            logs.append("├─ Reason: \(reason)")
            logs.append("└─ Unknown unavailability reason")
        }
        logs.append("")
        
        // 5. Session Creation Test
        logs.append("🔧 SESSION CREATION TEST:")
        logs.append("├─ Creating test session...")
        let testInstructions = Instructions {
            "You are a test assistant."
        }
        let testSession = LanguageModelSession(instructions: testInstructions)
        logs.append("├─ Session created: ✅")
        logs.append("└─ Type: \(type(of: testSession))")
        logs.append("")
        
        // 6. CurrencyAIEngine Check
        logs.append("💱 CURRENCY AI ENGINE:")
        logs.append("├─ Checking CurrencyAIEngine.shared...")
        logs.append("├─ isAvailable: \(CurrencyAIEngine.shared.isAvailable)")
        logs.append("├─ Description: \(CurrencyAIEngine.shared.availabilityDescription)")
        logs.append("└─ Engine initialized: \(CurrencyAIEngine.shared.isAvailable ? "✅" : "❌")")
        logs.append("")
        
        // 7. Simple Generation Test (only if available)
        if model.availability == .available {
            logs.append("🧪 SIMPLE GENERATION TEST:")
            logs.append("├─ Attempting basic text generation...")
            logs.append("└─ (This will be tested separately)")
        } else {
            logs.append("⚠️  CANNOT TEST GENERATION:")
            logs.append("└─ Model is not available")
        }
        logs.append("")
        
        // 8. Summary
        logs.append("═══════════════════════════════════════")
        logs.append("📋 SUMMARY:")
        if model.availability == .available {
            logs.append("✅ Model is AVAILABLE and ready to use")
            logs.append("✅ You can proceed with testing")
        } else {
            logs.append("❌ Model is NOT available")
            logs.append("⚠️  See availability reason above")
            logs.append("⚠️  Fix the issue to use on-device LLM")
        }
        logs.append("═══════════════════════════════════════")
        
        // Print all logs to console as well
        print("\n📋 DIAGNOSTIC COMPLETE - \(logs.count) log lines generated\n")
        for log in logs {
            print(log)
        }
        print("\n═══════════════════════════════════════\n")
        
        return logs
    }
    
    func testSimpleGeneration(completion: @escaping (Result<String, Error>) -> Void) {
        print("\n🧪 TEST SIMPLE GENERATION - Starting...")
        
        Task {
            do {
                let model = SystemLanguageModel.default
                print("├─ Model: \(model)")
                print("├─ Availability: \(model.availability)")
                
                guard model.availability == .available else {
                    print("├─ ❌ Model NOT available")
                    completion(.failure(NSError(domain: "DiagnosticEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not available"])))
                    return
                }
                
                print("├─ ✅ Model is available")
                print("├─ Creating session...")
                
                let instructions = Instructions {
                    "You are a helpful assistant. Answer briefly."
                }
                let session = LanguageModelSession(instructions: instructions)
                print("├─ ✅ Session created")
                
                let prompt = Prompt {
                    "Say 'Hello, I am working!' and nothing else."
                }
                print("├─ Sending prompt: 'Say Hello, I am working!'")
                
                let response = try await session.respond(to: prompt)
                print("├─ ✅ Got response!")
                print("├─ Response content: '\(response.content)'")
                print("└─ Test SUCCESSFUL! 🎉\n")
                
                completion(.success(response.content))
                
            } catch {
                print("├─ ❌ Test FAILED")
                print("├─ Error: \(error)")
                print("└─ Error details: \(error.localizedDescription)\n")
                completion(.failure(error))
            }
        }
    }
    
    private func getOSVersion() -> String {
        #if os(iOS)
        return "iOS \(UIDevice.current.systemVersion)"
        #elseif os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        return "Unknown OS"
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
        return "Unknown Device"
        #endif
    }
    
    private func getBuildInfo() -> String {
        let infoDictionary = Bundle.main.infoDictionary
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}

