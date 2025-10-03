//
//  currency_converterApp.swift
//  currency converter
//
//  Created by Darius on 9/23/25.
//

import SwiftUI

@main
struct currency_converterApp: App {
    var body: some Scene {
        WindowGroup {
            // PRODUCTION: Your normal app with circular layout + AI
            ContentView()
            
            // DEBUG: Uncomment to test LLM diagnostics
            // LLMDebugView()
            
            // TESTING: Uncomment to test structured Currency AI
            // CurrencyAITestView()
            
            // TESTING: Uncomment to test simple Foundation Models
            // SimpleAITest()
        }
    }
}
