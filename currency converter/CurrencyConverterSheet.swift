// CurrencyConverterSheet.swift
// Minimal AI conversion sheet wired to Foundation Models availability

import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

struct CurrencyConverterSheet: View {
    let amount: Double
    let base: String
    let target: String

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var resultText: String = ""
    @State private var errorText: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: AIEngine.shared.isAvailable ? "sparkles" : "sparkles.slash")
                        .foregroundStyle(AIEngine.shared.isAvailable ? .green : .secondary)
                    Text(AIEngine.shared.availabilityDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Group {
                    if isLoading {
                        ProgressView("Converting…")
                    } else if !errorText.isEmpty {
                        Text(errorText).foregroundStyle(.red)
                    } else if !resultText.isEmpty {
                        Text(resultText)
                            .font(.body)
                            .textSelection(.enabled)
                    } else {
                        Text("Ready to convert \(amount) \(base) → \(target)")
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    Task { await convert() }
                } label: {
                    Label("Convert with AI", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || !AIEngine.shared.isAvailable)
            }
            .padding()
            .navigationTitle("AI Convert")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private func convert() async {
        #if canImport(FoundationModels)
        guard AIEngine.shared.isAvailable else {
            errorText = "On-device model is unavailable on this device."
            return
        }
        isLoading = true
        defer { isLoading = false }

        let session = LanguageModelSession(instructions: """
        You are a concise FX assistant. Convert amounts using ISO currency codes. Avoid advice.
        Provide: converted amount (2 decimals) and a one-line explanation.
        """)

        let prompt = Prompt {
            "Convert \(amount) \(base) to \(target)."
            "Output as: <converted> and <explanation>."
        }

        do {
            let response = try await session.respond(to: prompt)
            resultText = response.content
            errorText = ""
        } catch {
            errorText = error.localizedDescription
        }
        #else
        errorText = "This build does not include Foundation Models."
        #endif
    }
}
