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
        let instructions = """
        You are an FX assistant. Be concise, avoid financial advice, and include caveats.
        Prefer structured answers when requested. Use ISO currency codes.
        """
        return LanguageModelSession(instructions: instructions)
    }()
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
        guard model.availability == .available else { return }
        // A lightweight no-op prompt to initialize internals. Errors are ignored.
        Task {
            _ = try? await session.respond(to: "Hello")
        }
        #endif
    }
}
