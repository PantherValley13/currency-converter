//
//  ContentView.swift
//  currency converter
//
//  Created by Darius on 9/23/25.
//

import SwiftUI
import Charts
import UIKit
import UserNotifications
import Combine
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Feature Models
private struct CurrencyAlertRule: Codable, Identifiable, Equatable {
    enum Direction: String, Codable, CaseIterable { case above, below }
    let id: UUID
    var base: String
    var target: String
    var threshold: Double
    var direction: Direction
}

private struct FXProviderProfile: Codable, Identifiable, Equatable {
    var id: String { key }
    let key: String
    let name: String
    let spreadPercent: Double   // applied to rate as a percentage spread
    let fixedFee: Double        // fixed fee in base currency amount
}

private struct CurrencyQuickPair: Codable, Hashable, Identifiable {
    var id: String { base + "→" + target }
    var base: String
    var target: String
}

private enum SelectionMode: String, CaseIterable, Identifiable {
    case base = "Base"
    case target = "Target"
    var id: String { rawValue }
}

struct ContentView: View {
    // MARK: - State
    @State private var amount: String = "100"
    @State private var baseCurrency: String = "USD"
    @State private var targetCurrency: String = "EUR"
    @State private var ringRadius: CGFloat = 180
    @State private var showAllLabels: Bool = false
    
    // AI Assistant State
    @ObservedObject private var aiAssistant = AIAssistantManager.shared
    @State private var showTravelInsights: Bool = false
    @State private var travelDestination: String = ""
    @State private var travelBudget: String = "1000"
    
    // Enhanced AI State (Added: Oct 2, 2025)
    // NEW: Apple Foundation Models integration with streaming and structured outputs
    // See: APPLE_AI_IMPLEMENTATION_GUIDE.md for details
    @State private var showEnhancedAISheet: Bool = false

    @State private var showHierarchy: Bool = true
    @State private var selectionMode: SelectionMode = .target
    @State private var searchText: String = ""
    @State private var favorites: [String] = ["USD", "EUR", "JPY"]
    @State private var recents: [String] = []

    // Ring interaction state
    @State private var ringRotation: Angle = .degrees(0)
    @State private var gestureStartAngle: Angle? = nil
    @State private var initialRotation: Angle = .degrees(0)

    // Live rates cache and state
    @AppStorage("cachedRatesJSON") private var cachedRatesJSON: String = ""
    @AppStorage("cachedRatesBase") private var cachedRatesBase: String = ""
    @AppStorage("cachedRatesUpdated") private var cachedRatesUpdated: Double = 0 // timeIntervalSince1970

    @State private var rates: [String: Double] = [:]
    @State private var lastUpdated: Date? = nil
    @State private var isRefreshing: Bool = false
    @State private var isOffline: Bool = false
    
    @State private var fmAvailable: Bool = false
    @State private var fmAvailabilityMessage: String = ""

    // Auto-refresh
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled: Bool = true
    @AppStorage("refreshIntervalMinutes") private var refreshIntervalMinutes: Double = 60

    // Fees mode
    @AppStorage("feesEnabled") private var feesEnabled: Bool = false
    @AppStorage("feePercent") private var feePercent: Double = 2.5

    // History/Chart state
    private enum HistoryRange: String, CaseIterable, Identifiable { case d7 = "7D", m1 = "1M", m3 = "3M", ytd = "YTD", y1 = "1Y"; var id: String { rawValue } }
    struct RatePoint: Identifiable { let id = UUID(); let date: Date; let value: Double }
    @State private var historyRange: HistoryRange = .d7
    @State private var history: [RatePoint] = []
    @State private var loadingHistory: Bool = false
    @State private var historyError: String? = nil
    @State private var showSMA7: Bool = false
    @State private var showSMA30: Bool = false
    @State private var showAlertsSheet: Bool = false
    @State private var selectedHistoryPoint: RatePoint? = nil

    // Ring snapping & options
    @AppStorage("snapOnRelease") private var snapOnRelease: Bool = true
    @AppStorage("autoSelectOnSnap") private var autoSelectOnSnap: Bool = true

    // Alerts & Provider profiles
    @AppStorage("alertRulesJSON") private var alertRulesJSON: String = "[]"
    @AppStorage("selectedProviderKey") private var selectedProviderKey: String = "interbank"

    // Sharing & Quick pairs
    @State private var showShareSheet: Bool = false
    @State private var quickPairs: [CurrencyQuickPair] = [
        CurrencyQuickPair(base: "USD", target: "EUR"),
        CurrencyQuickPair(base: "USD", target: "JPY"),
        CurrencyQuickPair(base: "EUR", target: "GBP")
    ]
    @AppStorage("quickPairsJSON") private var quickPairsJSON: String = "[]"
    @State private var showQuickPairsSheet: Bool = false
    @State private var showAIConvertSheet: Bool = false

    // Amount presets
    private let amountPresets: [String] = ["10","20","50","100","200","500"]
    private var amountPresetsActive: [String] {
        if let data = amountPresetsJSON.data(using: .utf8),
           let arr = try? JSONDecoder().decode([String].self, from: data), !arr.isEmpty { return arr }
        return ["10","20","50","100","200","500"]
    }
    @AppStorage("amountPresetsJSON") private var amountPresetsJSON: String = "[]"
    @State private var showPresetsSheet: Bool = false

    // Chart comparison
    @State private var compareCurrency: String? = nil
    @State private var compareHistory: [RatePoint] = []
    @State private var scrubberDate: Date? = nil
    @State private var scrubberValue: Double? = nil

    // Travel tools
    @State private var billAmount: String = ""
    @State private var tipPercentInput: Double = 10
    @State private var splitCount: Int = 2

    // Offline controls
    @AppStorage("forceOfflineMode") private var forceOfflineMode: Bool = false
    @AppStorage("offlinePackJSON") private var offlinePackJSON: String = ""
    @AppStorage("offlinePackSavedAt") private var offlinePackSavedAt: Double = 0

    // Toast / banner
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var showOfflineBanner: Bool = false

    // Watchlist persistence (comma-separated codes)
    @AppStorage("watchlistCodes") private var watchlistCodes: String = "EUR,JPY,GBP"
    private var watchlist: [String] {
        get { watchlistCodes.split(separator: ",").map { String($0) }.filter { !$0.isEmpty } }
        set { watchlistCodes = newValue.joined(separator: ",") }
    }

    // Alerts decoding/encoding
    private var alertRules: [CurrencyAlertRule] {
        get { (try? JSONDecoder().decode([CurrencyAlertRule].self, from: Data(alertRulesJSON.utf8))) ?? [] }
        set { alertRulesJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    // Provider profiles
    private var providerProfiles: [FXProviderProfile] {
        [
            FXProviderProfile(key: "interbank", name: "Interbank (No Spread)", spreadPercent: 0, fixedFee: 0),
            FXProviderProfile(key: "bank_standard", name: "Bank Standard", spreadPercent: 2.0, fixedFee: 2.0),
            FXProviderProfile(key: "fintech_fast", name: "Fintech Fast", spreadPercent: 0.6, fixedFee: 0.5)
        ]
    }
    private var selectedProvider: FXProviderProfile {
        providerProfiles.first { $0.key == selectedProviderKey } ?? providerProfiles[0]
    }

    // A small sample of currencies and reference rates (relative to USD) for demo purposes.
    private let currencies: [String] = [
        "USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "BRL", "ZAR", "SEK"
    ]
    
    // Currency display names (subset for demo)
    private let currencyNames: [String: String] = [
        "USD": "US Dollar",
        "EUR": "Euro",
        "GBP": "British Pound",
        "JPY": "Japanese Yen",
        "CAD": "Canadian Dollar",
        "AUD": "Australian Dollar",
        "CHF": "Swiss Franc",
        "CNY": "Chinese Yuan",
        "INR": "Indian Rupee",
        "BRL": "Brazilian Real",
        "ZAR": "South African Rand",
        "SEK": "Swedish Krona"
    ]

    private let defaultRates: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 147.0,
        "CAD": 1.35,
        "AUD": 1.49,
        "CHF": 0.88,
        "CNY": 7.25,
        "INR": 83.0,
        "BRL": 5.35,
        "ZAR": 18.4,
        "SEK": 10.9
    ]

    // MARK: - Body
    var body: some View {
        ZStack {
            // Enhanced background with subtle gradient
            RadialGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground).opacity(0.5),
                    Color(.tertiarySystemBackground)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 700
            )
            .ignoresSafeArea()

            TabView {
                // Convert tab
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        quickPairsStrip
                        aiSmartSuggestionsSection
                        circularConverter
                        resultCard
                        aiRateTrendSection
                        controlsRow
                    }
                    .padding()
                }
                .tabItem { Label("Convert", systemImage: "arrow.2.squarepath") }

                // AI Assistant tab
                AIAssistantView { request in
                    handleAIConversionRequest(request)
                } onTravelRequest: { destination, budget in
                    travelDestination = destination
                    travelBudget = String(Int(budget))
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        // Switch to Tools tab by presenting the sheet or a banner; here we generate insights directly
                        showTravelInsights = true
                    }
                    generateTravelInsights()
                }
                .tabItem { Label("AI Chat", systemImage: "sparkles") }

                // History tab
                ScrollView {
                    VStack(spacing: 16) {
                        historySection
                    }
                    .padding()
                }
                .tabItem { Label("History", systemImage: "chart.line.uptrend.xyaxis") }

                // Watchlist tab
                ScrollView {
                    VStack(spacing: 16) {
                        hierarchicalPanel
                        watchlistSection
                    }
                    .padding()
                }
                .tabItem { Label("Watchlist", systemImage: "eye") }

                // Tools tab
                ScrollView {
                    VStack(spacing: 16) {
                        aiTravelInsightsSection
                        aiAlertRecommendationsSection
                        travelToolsSection
                    }
                    .padding()
                }
                .tabItem { Label("Tools", systemImage: "wrench.and.screwdriver") }
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await refreshRates(triggeredByUser: true) }
            .task {
                // DON'T load cache first - let refreshRates() try API first!
                // loadCachedRates() will be called automatically if API fails
                loadAISuggestions()
                SupabaseManager.shared.logEnvironmentCheck()
                // Test Supabase connection
                await SupabaseManager.shared.testConnection()
                // Load quick pairs from storage (with migration support)
                loadQuickPairsFromStorage()
                
                // Try to fetch from API first (will load cache automatically if it fails)
                await refreshRates()
                
                evaluateAlertsIfNeeded()
                await refreshHistory()
                AIEngine.shared.warmUp()
                // Pre-warm enhanced AI engine (Added: Oct 2, 2025)
                // This reduces first-request latency by 30-50% by loading the model into memory
                // See: EnhancedAIEngine.swift for implementation details
                EnhancedAIEngine.shared.prewarmAll()
                fmAvailable = AIEngine.shared.isAvailable
                fmAvailabilityMessage = AIEngine.shared.availabilityDescription
                if forceOfflineMode || isOffline { await showOfflineBannerTemporarily() }
            }
            .onChange(of: baseCurrency) { _, _ in
                Task {
                    await refreshRates()
                    evaluateAlertsIfNeeded()
                }
            }
            .onChange(of: targetCurrency) { _, _ in
                Task {
                    await refreshHistory()
                    evaluateAlertsIfNeeded()
                    await refreshCompareHistory()
                }
            }
            .onChange(of: historyRange) { _, _ in
                Task { await refreshHistory() }
                Task { await refreshCompareHistory() }
            }
            .onChange(of: compareCurrency) { _, _ in
                Task { await refreshCompareHistory() }
            }
            .onChange(of: forceOfflineMode) { _, newValue in
                if newValue { Task { await showOfflineBannerTemporarily() } }
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                if shouldAutoRefreshNow {
                    Task { await refreshRates() }
                }
            }

            // Toast overlay
            if showToast {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                        Text(toastMessage).font(.footnote)
                        Spacer()
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(.quaternary))
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: showToast)
            }

            // Status banner (offline or online confirmation)
            if showOfflineBanner {
                VStack {
                    HStack(spacing: 8) {
                        if isOffline {
                            Image(systemName: "wifi.slash").foregroundStyle(.orange)
                            Text("Offline: showing cached rates").font(.caption).foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("Online: live rates updated").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(.thinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(.quaternary))
                    .padding(.top, 56)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showAlertsSheet) {
            AlertsManagerView(
                base: baseCurrency,
                target: targetCurrency,
                rules: alertRules,
                onSave: { newRules in
                    alertRulesJSON = (try? String(data: JSONEncoder().encode(newRules), encoding: .utf8)) ?? "[]"
                },
                onClose: { showAlertsSheet = false }
            )
        }
        .sheet(isPresented: $showShareSheet) { ActivityView(activityItems: [shareText]) }
        .sheet(isPresented: $showQuickPairsSheet) {
            QuickPairsManagerView(pairs: quickPairs, onSave: { updated in
                quickPairs = updated
                if let data = try? JSONEncoder().encode(updated) { quickPairsJSON = String(data: data, encoding: .utf8) ?? "[]" }
            })
        }
        .sheet(isPresented: $showPresetsSheet) {
            PresetsManagerView(presets: amountPresetsActive, onSave: { updated in
                if let data = try? JSONEncoder().encode(updated) { amountPresetsJSON = String(data: data, encoding: .utf8) ?? "[]" }
            })
        }
        // Original AI Convert sheet (basic implementation)
        .sheet(isPresented: $showAIConvertSheet) {
            CurrencyConverterSheet(
                amount: numericAmount,
                base: baseCurrency,
                target: targetCurrency
            )
        }
        // NEW: Enhanced AI sheet (Added: Oct 2, 2025)
        // Presents ImprovedAIConversionView with:
        // - Real-time streaming responses (text appears progressively)
        // - Structured CurrencyConversionResponse (type-safe)
        // - Beautiful cards with animations
        // - Proper error handling and availability checking
        // Requires: macOS 15.0+/iOS 18.0+ and Apple Intelligence enabled
        .sheet(isPresented: $showEnhancedAISheet) {
            #if canImport(FoundationModels)
            ImprovedAIConversionView(
                amount: numericAmount,
                baseCurrency: baseCurrency,
                targetCurrency: targetCurrency,
                currentRate: activeRates[targetCurrency]
            )
            #else
            // Fallback for devices without Foundation Models support
            Text("Foundation Models not available")
                .padding()
            #endif
        }
    }

    // MARK: - Quick Pairs Strip
    private var quickPairsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(quickPairs) { pair in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            applyQuickPair(pair)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(pair.base)
                                .font(.caption.weight(.semibold))
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(pair.target)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.accentColor.opacity(0.12))
                                .shadow(color: Color.accentColor.opacity(0.15), radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Quick pair \(pair.base) to \(pair.target)"))
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
    }

    private func applyQuickPair(_ pair: CurrencyQuickPair) {
        baseCurrency = pair.base
        targetCurrency = pair.target
        recordRecent(pair.base)
        recordRecent(pair.target)
        haptic()
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 16) {
            // Enhanced segmented picker with better styling
            HStack {
                Picker("Mode", selection: $selectionMode) {
                    ForEach(SelectionMode.allCases) { m in
                        Text(m.rawValue)
                            .font(.subheadline.weight(.medium))
                            .tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            
            // Refined amount input with better visual hierarchy
            HStack(spacing: 16) {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
                    )
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        swapCurrencies()
                    }
                }) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.tint)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
            // Enhanced presets row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(amountPresetsActive, id: \.self) { p in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                amount = p
                            }
                        }) {
                            Text(p)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(amount == p ? Color.accentColor : Color.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(amount == p ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(
                                            amount == p ? Color.accentColor.opacity(0.4) : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Set amount to \(p)"))
                    }
                }
                .padding(.top, 6)
            }
            // Enhanced currency selector buttons
            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectionMode = .base
                        haptic()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(emojiForStatic(code: baseCurrency))
                            .font(.title3)
                        Text(baseCurrency)
                            .font(.body.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(selectionMode == .base ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                            .shadow(color: selectionMode == .base ? Color.accentColor.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                selectionMode == .base ? Color.accentColor : Color(.separator).opacity(0.5),
                                lineWidth: selectionMode == .base ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .minTapTarget()
                .accessibilityLabel(Text("Select base currency"))
                .accessibilityValue(Text(baseCurrency))

                Image(systemName: "arrow.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectionMode = .target
                        haptic()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(emojiForStatic(code: targetCurrency))
                            .font(.title3)
                        Text(targetCurrency)
                            .font(.body.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(selectionMode == .target ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                            .shadow(color: selectionMode == .target ? Color.accentColor.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                selectionMode == .target ? Color.accentColor : Color(.separator).opacity(0.5),
                                lineWidth: selectionMode == .target ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .minTapTarget()
                .accessibilityLabel(Text("Select target currency"))
                .accessibilityValue(Text(targetCurrency))

                Spacer()
            }
        }
    }

    private func swapCurrencies() {
        let tmp = baseCurrency
        baseCurrency = targetCurrency
        targetCurrency = tmp
        haptic()
    }

    // MARK: - Circular Converter (Enhanced circular ring layout)
    private var circularConverter: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Select \(selectionMode == .base ? "Base" : "Target") Currency")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Toggle("Labels", isOn: $showAllLabels)
                    .labelsHidden()
                    .tint(Color.accentColor)
            }
            ZStack {
                // Enhanced ring background with subtle glow
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.3),
                                Color.accentColor.opacity(0.1),
                                Color.secondary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: ringRadius * 2, height: ringRadius * 2)
                    .shadow(color: Color.accentColor.opacity(0.1), radius: 12, x: 0, y: 0)

                CircleRing(count: currencies.count, radius: ringRadius, rotationOffset: ringRotation) { idx in
                    let code = currencies[idx]
                    CurrencyChip(
                        code: code,
                        isSelected: (selectionMode == .base ? code == baseCurrency : code == targetCurrency),
                        showLabel: showAllLabels
                    ) {
                        selectCurrency(code)
                    }
                    .minTapTarget()
                }

                // Enhanced center input square with refined styling
                let squareSize = min(ringRadius * 1.2, 240)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemBackground),
                                Color(.secondarySystemBackground).opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        VStack(spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Text(emojiForStatic(code: selectionMode == .base ? baseCurrency : targetCurrency))
                                        .font(.title2)
                                    Text(selectionMode == .base ? baseCurrency : targetCurrency)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        swapCurrencies()
                                    }
                                }) {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.tint)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            Circle()
                                                .fill(Color.accentColor.opacity(0.15))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            TextField("Amount", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.title2.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.tertiarySystemBackground))
                                )
                            
                            Stepper("", value: Binding(
                                get: { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0 },
                                set: { newVal in amount = formatAmount(newVal) }
                            ), in: 0...1_000_000, step: 1)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(16)
                    )
                    .frame(width: squareSize, height: squareSize)
                    .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
                    )

                // Enhanced top indicator with better visibility
                VStack(spacing: 4) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                    Text("Top")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .offset(y: -(ringRadius + 24))
            }
            .frame(width: ringRadius * 2, height: ringRadius * 2)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let center = CGPoint(x: ringRadius, y: ringRadius)
                        let current = angleFrom(center: center, to: value.location)
                        if gestureStartAngle == nil {
                            gestureStartAngle = current
                            initialRotation = ringRotation
                        } else if let start = gestureStartAngle {
                            ringRotation = initialRotation + (current - start)
                        }
                    }
                    .onEnded { _ in
                        gestureStartAngle = nil
                        if snapOnRelease { snapToNearestTop() }
                    }
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground).opacity(0.6),
                            Color(.tertiarySystemBackground).opacity(0.4)
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

    // MARK: - Hierarchical Panel
    private var hierarchicalPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup("Currencies") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                    if !favoritesFiltered.isEmpty {
                        Text("Favorites").font(.subheadline).foregroundStyle(.secondary)
                        currencyList(favoritesFiltered)
                    }
                    if !recentsFiltered.isEmpty {
                        Text("Recents").font(.subheadline).foregroundStyle(.secondary)
                        currencyList(recentsFiltered)
                    }
                    Text("All").font(.subheadline).foregroundStyle(.secondary)
                    currencyList(filteredAll)
                }
                .padding(.top, 8)
            }
            .disclosureGroupStyle()
        }
    }

    // MARK: - Enhanced Result Card
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Result")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    HStack(spacing: 4) {
                        Text("\(amount)")
                            .font(.subheadline.weight(.medium))
                        Text(baseCurrency)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(targetCurrency)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedPrimaryResult)
                        .font(.title.bold())
                        .monospacedDigit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    if !isOffline {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text("Live")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Divider()
                .padding(.vertical, 4)
            
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        copyResultToClipboard()
                    }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        pasteAndConvert()
                    }
                } label: {
                    Label("Paste", systemImage: "clipboard")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: isRefreshing ? "arrow.clockwise" : "clock")
                            .font(.caption2)
                            .symbolEffect(.rotate, isActive: isRefreshing)
                        Text(lastUpdatedDisplay)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            HStack {
                Label("Provider", systemImage: "building.2")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Provider", selection: $selectedProviderKey) {
                    ForEach(providerProfiles, id: \.key) { p in
                        Text(p.name).tag(p.key)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.accentColor)
                .frame(maxWidth: 220)
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

    // MARK: - History Section (simple chart)
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup("History \(baseCurrency)→\(targetCurrency)") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Range", selection: $historyRange) {
                        ForEach(HistoryRange.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Compare")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Compare", selection: Binding(get: { compareCurrency ?? "" }, set: { compareCurrency = $0.isEmpty ? nil : $0 })) {
                            Text("None").tag("")
                            ForEach(currencies.filter { $0 != targetCurrency }, id: \.self) { code in
                                Text(code).tag(code)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if loadingHistory {
                        ProgressView().padding(.top, 8)
                    } else if let err = historyError {
                        Text(err).foregroundStyle(.secondary)
                    } else if history.isEmpty {
                        Text("No data").foregroundStyle(.secondary)
                    } else {
                        Chart {
                            ForEach(history) { pt in
                                LineMark(
                                    x: .value("Date", pt.date),
                                    y: .value("Rate", pt.value)
                                )
                                .foregroundStyle(.tint)
                            }
                            ForEach(compareHistory) { pt in
                                LineMark(
                                    x: .value("Date", pt.date),
                                    y: .value("Rate", pt.value)
                                )
                                .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 200)
                    }
                }
                .padding(.top, 8)
            }
            .disclosureGroupStyle()
        }
    }

    // MARK: - Watchlist Section
    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup("Watchlist") {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(watchlist, id: \.self) { code in
                            CurrencyChip(
                                code: code,
                                isSelected: (selectionMode == .base ? code == baseCurrency : code == targetCurrency),
                                showLabel: true
                            ) {
                                selectCurrency(code)
                            }
                            .contextMenu {
                                Button(role: .destructive) { removeFromWatchlist(code) } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                        Button {
                            addToWatchlist(selectionMode == .base ? baseCurrency : targetCurrency)
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                        .accessibilityLabel(Text("Add current currency to watchlist"))
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }
            .disclosureGroupStyle()
        }
    }

    // MARK: - Controls Row
    private var controlsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    Task { await refreshRates(triggeredByUser: true) }
                } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)

                Button { showShareSheet = true } label: { Label("Share", systemImage: "square.and.arrow.up") }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)

                Button { showAlertsSheet = true } label: { Label("Alerts", systemImage: "bell") }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)

                Button { showQuickPairsSheet = true } label: { Label("Pairs", systemImage: "square.grid.2x2") }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)

                Button { showPresetsSheet = true } label: { Label("Presets", systemImage: "slider.horizontal.3") }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)

                // Original AI Convert button (basic text responses)
                Button { showAIConvertSheet = true } label: { Label("AI Convert", systemImage: "sparkles") }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                
                // NEW: Enhanced AI button (Added: Oct 2, 2025)
                // Features: Streaming responses, structured outputs, better UX
                // Uses: Apple Foundation Models with @Generable types
                // See: ImprovedAIConversionView.swift for UI implementation
                Button { showEnhancedAISheet = true } label: { Label("Enhanced AI", systemImage: "sparkles.square.filled.on.square") }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent) // Prominent blue style to distinguish from old button
            }
            HStack(spacing: 8) {
                Button { saveOfflinePack() } label: { Label("Save", systemImage: "tray.and.arrow.down") }
                    .accessibilityLabel(Text("Save offline rates pack"))
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                Button { loadOfflinePack() } label: { Label("Load", systemImage: "tray.and.arrow.up") }
                    .accessibilityLabel(Text("Load offline rates pack"))
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                Button { addQuickAlertDrop1Percent() } label: { Label("1% Alert", systemImage: "bell.badge") }
                    .accessibilityLabel(Text("Add alert for 1 percent drop"))
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                Toggle(isOn: $forceOfflineMode) { Text("Force Offline") }
                    .toggleStyle(.switch)
            }
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(fmAvailable ? .green : .secondary)
                Text(fmAvailabilityMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Travel Tools Section
    private var travelToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup("Travel Tools") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Bill Amount")
                        Spacer()
                        TextField("0", text: $billAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Tip")
                        Spacer()
                        Slider(value: $tipPercentInput, in: 0...30, step: 1)
                            .frame(maxWidth: 180)
                        Text("\(Int(tipPercentInput))%")
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                    HStack {
                        Text("Split")
                        Spacer()
                        Stepper(value: $splitCount, in: 1...20) {
                            Text("\(splitCount)x")
                                .monospacedDigit()
                        }
                        .frame(width: 120, alignment: .trailing)
                    }

                    Divider()

                    let bill = Double(billAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
                    let tipValue = bill * tipPercentInput / 100
                    let total = bill + tipValue
                    let perPerson = total / Double(max(splitCount, 1))

                    VStack(spacing: 8) {
                        HStack {
                            Text("Tip Amount")
                            Spacer()
                            Text(formatCurrency(tipValue, code: targetCurrency))
                                .bold()
                        }
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(formatCurrency(total, code: targetCurrency))
                                .bold()
                        }
                        HStack {
                            Text("Per Person")
                            Spacer()
                            Text(formatCurrency(perPerson, code: targetCurrency))
                                .bold()
                        }
                    }
                }
                .padding(.top, 8)
            }
            .disclosureGroupStyle()
        }
    }

    private func formatCurrency(_ value: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
    private func formatAmount(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        nf.usesGroupingSeparator = false
        return nf.string(from: NSNumber(value: value)) ?? String(value)
    }

    private var shareText: String {
        "\(amount) \(baseCurrency) → \(formattedPrimaryResult) (\(baseCurrency)→\(targetCurrency))"
    }

    // UIKit share sheet wrapper
    private struct ActivityView: UIViewControllerRepresentable {
        let activityItems: [Any]
        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }

    // MARK: - Helper to load quick pairs with migration support
    private func loadQuickPairsFromStorage() {
        guard !quickPairsJSON.isEmpty, let data = quickPairsJSON.data(using: .utf8) else { return }
        // Preferred: decode as [CurrencyQuickPair]
        if let arr = try? JSONDecoder().decode([CurrencyQuickPair].self, from: data), !arr.isEmpty {
            self.quickPairs = arr
            return
        }
        // Legacy form 1: [[String]] where each item is [base, target]
        if let arr = try? JSONDecoder().decode([[String]].self, from: data) {
            let mapped = arr.compactMap { item -> CurrencyQuickPair? in
                guard item.count >= 2 else { return nil }
                return CurrencyQuickPair(base: item[0], target: item[1])
            }
            if !mapped.isEmpty {
                self.quickPairs = mapped
                if let newData = try? JSONEncoder().encode(mapped) { self.quickPairsJSON = String(data: newData, encoding: .utf8) ?? "[]" }
                return
            }
        }
        // Legacy form 2: [[String:String]] with keys "base"/"target" or "0"/"1"
        if let arr = try? JSONDecoder().decode([[String:String]].self, from: data) {
            let mapped = arr.compactMap { dict -> CurrencyQuickPair? in
                if let b = dict["base"], let t = dict["target"] { return CurrencyQuickPair(base: b, target: t) }
                if let b = dict["0"], let t = dict["1"] { return CurrencyQuickPair(base: b, target: t) }
                return nil
            }
            if !mapped.isEmpty {
                self.quickPairs = mapped
                if let newData = try? JSONEncoder().encode(mapped) { self.quickPairsJSON = String(data: newData, encoding: .utf8) ?? "[]" }
                return
            }
        }
    }

    // MARK: - Ring math helpers
    private func angleFrom(center: CGPoint, to point: CGPoint) -> Angle {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let radians = atan2(dy, dx)
        return .radians(Double(radians))
    }

    private func normalizedDegrees(_ angle: Angle) -> Double {
        var deg = angle.degrees.truncatingRemainder(dividingBy: 360)
        if deg < -180 { deg += 360 }
        if deg > 180 { deg -= 360 }
        return deg
    }

    private func snapToNearestTop() {
        guard snapOnRelease else { return }
        let count = currencies.count
        // For each index, compute current angle at which the item is placed
        var nearestIndex: Int = 0
        var bestDistance = Double.greatestFiniteMagnitude
        for i in 0..<count {
            let base = Angle(degrees: (Double(i) / Double(max(count, 1))) * 360.0 - 90)
            let current = base + ringRotation
            // Distance to top (-90 degrees) equals current.degrees - (-90)
            let dist = abs(normalizedDegrees(current - .degrees(-90)))
            if dist < bestDistance {
                bestDistance = dist
                nearestIndex = i
            }
        }
        let baseAngle = Angle(degrees: (Double(nearestIndex) / Double(max(count, 1))) * 360.0 - 90)
        let targetRotation = .degrees(-90) - baseAngle
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            ringRotation = targetRotation
        }
        if autoSelectOnSnap {
            let code = currencies[nearestIndex]
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                switch selectionMode {
                case .base:
                    baseCurrency = code
                case .target:
                    targetCurrency = code
                }
                recordRecent(code)
            }
            haptic()
        }
    }

    // MARK: - Haptics
    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
#if targetEnvironment(simulator)
        // No-op on Simulator to avoid haptic errors
        return
#else
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
#endif
    }

    // MARK: - Rates source
    private var activeRates: [String: Double] {
        rates.isEmpty ? defaultRates : rates
    }

    // MARK: - Computation
    private var numericAmount: Double {
        Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var numericResultProviderAdjusted: Double {
        guard let base = activeRates[baseCurrency], let target = activeRates[targetCurrency], base > 0 else { return 0 }
        let usdValue = numericAmount / base
        let raw = usdValue * target
        return applyProviderAdjustments(amountInTarget: raw, baseAmount: numericAmount)
    }

    private func applyProviderAdjustments(amountInTarget: Double, baseAmount: Double) -> Double {
        // Apply spread: reduce target amount by spreadPercent
        let spreadFactor = max(0, 1 - selectedProvider.spreadPercent/100)
        var result = amountInTarget * spreadFactor
        // Apply fixed fee converted into target currency using current rate approximation
        if selectedProvider.fixedFee > 0, let base = activeRates[baseCurrency], let target = activeRates[targetCurrency], base > 0 {
            let usd = selectedProvider.fixedFee / base
            let feeInTarget = usd * target
            result = max(0, result - feeInTarget)
        }
        // Optional extra user fee switch (legacy)
        if feesEnabled {
            result *= max(0, 1 - feePercent/100)
        }
        return result
    }

    private var formattedPrimaryResult: String {
        let formatter = NumberFormatter(); formatter.numberStyle = .currency; formatter.currencyCode = targetCurrency
        return formatter.string(from: NSNumber(value: numericResultProviderAdjusted)) ?? "—"
    }

    private func formattedConversion(to target: String) -> String {
        let value: Double
        if let base = activeRates[baseCurrency], let tgt = activeRates[target], base > 0 {
            let usdValue = numericAmount / base
            value = usdValue * tgt
        } else {
            value = 0
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = target
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    // MARK: - Status formatting
    private var lastUpdatedDisplay: String {
        if let d = lastUpdated {
            let df = DateFormatter()
            df.dateStyle = .none
            df.timeStyle = .short
            return "Updated " + df.string(from: d)
        } else if !rates.isEmpty {
            return "Updated just now"
        } else if !cachedRatesJSON.isEmpty {
            return "Using cached rates"
        } else {
            return "No live rates yet"
        }
    }

    private var shouldAutoRefreshNow: Bool {
        guard autoRefreshEnabled else { return false }
        guard let last = lastUpdated else { return true }
        let interval = refreshIntervalMinutes * 60
        return Date().timeIntervalSince(last) >= interval
    }
    
    private var historyStats: (min: Double, max: Double, change: Double)? {
        guard history.count >= 2 else { return nil }
        let values = history.map { $0.value }
        guard let minV = values.min(), let maxV = values.max(), let first = values.first, let last = values.last else { return nil }
        let change = (last - first) / first
        return (minV, maxV, change)
    }

    // MARK: - Hierarchical helpers
    private var filteredAll: [String] {
        let base = currencies
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private var favoritesFiltered: [String] {
        favorites.filter { filteredAll.contains($0) }
    }

    private var recentsFiltered: [String] {
        recents.filter { filteredAll.contains($0) }
    }

    private var groupedAll: [String: [String]] {
        Dictionary(grouping: filteredAll, by: { String($0.prefix(1)) })
            .mapValues { $0.sorted() }
    }

    private var groupedAllKeys: [String] {
        groupedAll.keys.sorted()
    }

    private func recordRecent(_ code: String) {
        var set = LinkedHashSet(recents)
        set.insertAtFront(code)
        recents = Array(set.prefix(8))
    }

    private func selectCurrency(_ code: String) {
        switch selectionMode {
        case .base: baseCurrency = code
        case .target: targetCurrency = code
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            recordRecent(code)
            haptic()
        }
    }

    private func addToWatchlist(_ code: String) {
        var set = LinkedHashSet(watchlist)
        set.insertAtFront(code)
        watchlistCodes = Array(set.prefix(12)).joined(separator: ",")
    }

    private func removeFromWatchlist(_ code: String) {
        var arr = watchlist
        arr.removeAll { $0 == code }
        watchlistCodes = arr.joined(separator: ",")
    }

    private func toggleWatchlist(_ code: String) {
        if watchlist.contains(code) {
            removeFromWatchlist(code)
        } else {
            addToWatchlist(code)
        }
    }

    private func moveWatchlist(_ code: String, direction: Int) {
        var arr = watchlist
        guard let idx = arr.firstIndex(of: code) else { return }
        let newIdx = max(0, min(arr.count-1, idx + direction))
        guard newIdx != idx else { return }
        arr.remove(at: idx)
        arr.insert(code, at: newIdx)
        watchlistCodes = arr.joined(separator: ",")
    }

    @ViewBuilder
    private func currencyList(_ items: [String]) -> some View {
        ForEach(items, id: \.self) { code in
            Button {
                selectCurrency(code)
            } label: {
                HStack(spacing: 12) {
                    Text(emojiForStatic(code: code))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(code).font(.body)
                        if let name = currencyNames[code] {
                            Text(name).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if (selectionMode == .base && code == baseCurrency) || (selectionMode == .target && code == targetCurrency) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.06))
            )
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if watchlist.contains(code) {
                    Button(role: .destructive) { removeFromWatchlist(code) } label: {
                        Label("Remove", systemImage: "minus.circle")
                    }
                } else {
                    Button { addToWatchlist(code) } label: {
                        Label("Watch", systemImage: "eye")
                    }
                    .tint(.blue)
                }
            }
        }
    }

    private func emojiForStatic(code: String) -> String {
        switch code {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "JPY": return "🇯🇵"
        case "CAD": return "🇨🇦"
        case "AUD": return "🇦🇺"
        case "CHF": return "🇨🇭"
        case "CNY": return "🇨🇳"
        case "INR": return "🇮🇳"
        case "BRL": return "🇧🇷"
        case "ZAR": return "🇿🇦"
        case "SEK": return "🇸🇪"
        default: return "💱"
        }
    }

    // MARK: - Alerts
    private func evaluateAlertsIfNeeded() {
        guard !alertRules.isEmpty else { return }
        // Current rate for base->target in target currency for 1 base unit
        guard let base = activeRates[baseCurrency], let target = activeRates[targetCurrency], base > 0 else { return }
        let current = (1.0 / base) * target
        var rules = alertRules
        var fired: [CurrencyAlertRule] = []
        for r in rules where r.base == baseCurrency && r.target == targetCurrency {
            switch r.direction {
            case .above: if current >= r.threshold { fired.append(r) }
            case .below: if current <= r.threshold { fired.append(r) }
            }
        }
        if let first = fired.first {
            toastMessage = String(format: "Alert: %@→%@ %@ %.4f", first.base, first.target, first.direction == .above ? ">=" : "<=", first.threshold)
            scheduleLocalNotification(toastMessage)
            withAnimation { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { showToast = false } }
            // Remove fired rule(s) for now (simple behavior)
            rules.removeAll { fired.contains($0) }
            alertRulesJSON = (try? String(data: JSONEncoder().encode(rules), encoding: .utf8)) ?? "[]"
        }
    }

    private func addQuickAlertDrop1Percent() {
        // Add an alert for current pair: trigger when rate drops 1% from now
        guard let base = activeRates[baseCurrency], let target = activeRates[targetCurrency], base > 0 else { return }
        let current = (1.0 / base) * target
        let rule = CurrencyAlertRule(id: UUID(), base: baseCurrency, target: targetCurrency, threshold: current * 0.99, direction: .below)
        var rules = alertRules
        rules.append(rule)
        alertRulesJSON = (try? String(data: JSONEncoder().encode(rules), encoding: .utf8)) ?? "[]"
        toastMessage = "Alert added for 1% drop"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { showToast = false } }
    }

    // MARK: - Notifications
    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    private func scheduleLocalNotification(_ message: String) {
        requestNotificationPermissionIfNeeded()
        let content = UNMutableNotificationContent()
        content.title = "FX Alert"
        content.body = message
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
    // MARK: - Offline Banner Helper
    @MainActor
    private func showOfflineBannerTemporarily(duration: TimeInterval = 3.0) {
        withAnimation { showOfflineBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation { showOfflineBanner = false }
        }
    }

    // MARK: - Clipboard
    private func copyResultToClipboard() {
        UIPasteboard.general.string = formattedPrimaryResult
        toastMessage = "Copied"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { withAnimation { showToast = false } }
    }
    private func pasteAndConvert() {
        if let str = UIPasteboard.general.string {
            // Extract first number in the string
            if let num = Double(str.replacingOccurrences(of: ",", with: ".").components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()) {
                amount = String(num)
            }
        }
    }

    // MARK: - Networking & Cache
    private struct RatesResponse: Decodable {
        let base: String
        let rates: [String: Double]
        let date: String?
    }

    private actor RatesService {
        // Provider-aware endpoint builder. Swap endpoints/keys per provider here.
        private struct ProviderEndpoints {
            let latestURL: URL
            let timeseriesURL: (String, String, String, String) -> URL // base, target, start, end

            static func forProvider(_ key: String) -> ProviderEndpoints {
                // Default: exchangerate.host for all providers until dedicated APIs are plugged in.
                // TODO: Replace per-provider endpoints and add API keys/headers as needed.
                let latest: (String) -> URL = { base in
                    var comps = URLComponents(string: "https://api.exchangerate.host/latest")!
                    comps.queryItems = [URLQueryItem(name: "base", value: base)]
                    return comps.url!
                }
                let timeseries: (String, String, String, String) -> URL = { base, target, start, end in
                    var comps = URLComponents(string: "https://api.exchangerate.host/timeseries")!
                    comps.queryItems = [
                        URLQueryItem(name: "base", value: base),
                        URLQueryItem(name: "symbols", value: target),
                        URLQueryItem(name: "start_date", value: start),
                        URLQueryItem(name: "end_date", value: end)
                    ]
                    return comps.url!
                }
                // Route by provider key if you have different services:
                switch key {
                case "interbank":
                    return ProviderEndpoints(latestURL: latest("USD"), timeseriesURL: timeseries)
                case "bank_standard":
                    // TODO: Point to your bank API endpoints (auth/headers if needed)
                    return ProviderEndpoints(latestURL: latest("USD"), timeseriesURL: timeseries)
                case "fintech_fast":
                    // TODO: Point to your fintech API endpoints (auth/headers if needed)
                    return ProviderEndpoints(latestURL: latest("USD"), timeseriesURL: timeseries)
                default:
                    return ProviderEndpoints(latestURL: latest("USD"), timeseriesURL: timeseries)
                }
            }

            // Helper to produce the proper latest URL for a given base each call
            func latest(for base: String) -> URL {
                var comps = URLComponents(url: latestURL, resolvingAgainstBaseURL: false)!
                // Ensure base is applied even if latestURL was constructed with a placeholder
                var items = comps.queryItems ?? []
                items.removeAll { $0.name == "base" }
                items.append(URLQueryItem(name: "base", value: base))
                comps.queryItems = items
                return comps.url!
            }
        }

        func fetchRates(base: String, providerKey: String) async throws -> RatesResponse {
            let endpoints = ProviderEndpoints.forProvider(providerKey)
            let url = endpoints.latest(for: base)
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
            return try JSONDecoder().decode(RatesResponse.self, from: data)
        }
        
        func fetchHistory(base: String, target: String, range: HistoryRange, providerKey: String) async throws -> [RatePoint] {
            let cal = Calendar.current
            let end = Date()
            let start: Date
            switch range {
            case .d7: start = cal.date(byAdding: .day, value: -7, to: end)!
            case .m1: start = cal.date(byAdding: .month, value: -1, to: end)!
            case .m3: start = cal.date(byAdding: .month, value: -3, to: end)!
            case .ytd:
                let comps = cal.dateComponents([.year], from: end)
                start = cal.date(from: DateComponents(year: comps.year, month: 1, day: 1))!
            case .y1: start = cal.date(byAdding: .year, value: -1, to: end)!
            }
            let df = DateFormatter()
            df.calendar = cal
            df.dateFormat = "yyyy-MM-dd"
            let startStr = df.string(from: start)
            let endStr = df.string(from: end)

            let endpoints = ProviderEndpoints.forProvider(providerKey)
            let url = endpoints.timeseriesURL(base, target, startStr, endStr)
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 { throw URLError(.badServerResponse) }
            struct TSResp: Decodable { let rates: [String: [String: Double]] }
            let ts = try JSONDecoder().decode(TSResp.self, from: data)
            let points: [RatePoint] = ts.rates.compactMap { (k, v) in
                guard let val = v[target] else { return nil }
                return RatePoint(date: df.date(from: k) ?? Date(), value: val)
            }
            .sorted(by: { $0.date < $1.date })
            return points
        }
    }

    private static let service = RatesService()

    @MainActor
    private func refreshRates(triggeredByUser: Bool = false) async {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("💱 REFRESH RATES - Starting")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Base Currency: \(baseCurrency)")
        print("🔧 Provider: \(selectedProviderKey)")
        print("👤 User Triggered: \(triggeredByUser)")
        print("📡 Force Offline Mode: \(forceOfflineMode)")
        
        if forceOfflineMode {
            print("⚠️  Force offline mode enabled - loading cache")
            loadCachedRates()
            isOffline = true
            await showOfflineBannerTemporarily()
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            print("🌐 Fetching rates from API...")
            print("📡 URL: https://api.exchangerate.host/latest?base=\(baseCurrency)")
            
            let resp = try await Self.service.fetchRates(base: baseCurrency, providerKey: selectedProviderKey)
            
            print("✅ API SUCCESS!")
            print("├─ Base: \(resp.base)")
            print("├─ Currencies: \(resp.rates.count) rates received")
            print("├─ Date: \(resp.date ?? "N/A")")
            print("└─ Sample rates: USD→EUR=\(resp.rates["EUR"] ?? 0), USD→GBP=\(resp.rates["GBP"] ?? 0)")
            
            withAnimation(.easeInOut(duration: 0.2)) {
                self.rates = resp.rates.merging([resp.base: 1.0]) { current, _ in current }
                self.lastUpdated = Date()
                self.isOffline = false
            }
            saveCache(base: resp.base, rates: self.rates, updated: self.lastUpdated!)
            
            // Show success banner briefly
            if triggeredByUser {
                await showOfflineBannerTemporarily(duration: 2.0)
            }
            
            print("💾 Rates cached successfully")
            print("🎉 App is ONLINE - using live rates")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
        } catch {
            print("❌ API FAILED")
            print("├─ Error: \(error.localizedDescription)")
            print("├─ Error type: \(type(of: error))")
            print("└─ Falling back to cached rates...")
            
            // On failure, try cache
            loadCachedRates()
            isOffline = true
            await showOfflineBannerTemporarily()
            
            print("📦 Loaded cached rates")
            print("⚠️  App is OFFLINE - using cached data")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            if triggeredByUser {
                toastMessage = "Failed to refresh rates"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { showToast = false }
                }
            }
        }
    }
    
    @MainActor
    private func refreshHistory() async {
        loadingHistory = true
        historyError = nil
        defer { loadingHistory = false }
        do {
            history = try await Self.service.fetchHistory(base: baseCurrency, target: targetCurrency, range: historyRange, providerKey: selectedProviderKey)
        } catch {
            history = []
            historyError = "Failed to load history"
            toastMessage = "Failed to load history"
            withAnimation { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showToast = false }
            }
        }
    }
    
    @MainActor
    private func refreshCompareHistory() async {
        compareHistory = []
        guard let comp = compareCurrency else { return }
        do {
            compareHistory = try await Self.service.fetchHistory(base: baseCurrency, target: comp, range: historyRange, providerKey: selectedProviderKey)
        } catch {
            compareHistory = []
        }
    }

    private func saveOfflinePack() {
        // Save current active rates as an offline pack
        let payload: [String: Any] = [
            "base": baseCurrency,
            "rates": activeRates,
            "savedAt": Date().timeIntervalSince1970
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            offlinePackJSON = String(data: data, encoding: .utf8) ?? ""
            offlinePackSavedAt = Date().timeIntervalSince1970
            toastMessage = "Offline pack saved"
            withAnimation { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { showToast = false } }
        }
    }
    private func loadOfflinePack() {
        guard !offlinePackJSON.isEmpty, let data = offlinePackJSON.data(using: .utf8) else { return }
        if let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let base = obj["base"] as? String,
           let ratesDict = obj["rates"] as? [String: Double],
           let savedAt = obj["savedAt"] as? Double {
            self.rates = ratesDict.merging([base: 1.0]) { current, _ in current }
            self.lastUpdated = Date(timeIntervalSince1970: savedAt)
            self.isOffline = true
            self.forceOfflineMode = true
            Task { await showOfflineBannerTemporarily() }
            toastMessage = "Loaded offline pack"
            withAnimation { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { showToast = false } }
        }
    }

    private func saveCache(base: String, rates: [String: Double], updated: Date) {
        let payload: [String: Any] = ["base": base, "rates": rates, "updated": updated.timeIntervalSince1970]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            cachedRatesJSON = String(data: data, encoding: .utf8) ?? ""
            cachedRatesBase = base
            cachedRatesUpdated = updated.timeIntervalSince1970
        }
    }

    private func loadCachedRates() {
        guard !cachedRatesJSON.isEmpty, let data = cachedRatesJSON.data(using: .utf8) else { return }
        if let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let base = obj["base"] as? String,
           let ratesDict = obj["rates"] as? [String: Double],
           let updatedTS = obj["updated"] as? Double {
            self.rates = ratesDict.merging([base: 1.0]) { current, _ in current }
            self.lastUpdated = Date(timeIntervalSince1970: updatedTS)
            self.isOffline = true
        }
    }
    
    // MARK: - AI Assistant Sections
    
    private var aiSmartSuggestionsSection: some View {
        Group {
            if !aiAssistant.smartSuggestions.isEmpty {
                SmartSuggestionsView { suggestion in
                    handleSmartSuggestion(suggestion)
                }
            }
        }
    }
    
    private var aiRateTrendSection: some View {
        RateTrendSectionView(
            history: history,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency
        )
    }
    
    private var aiTravelInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Travel Assistant")
                .font(.title2.weight(.bold))
            
            if let insight = aiAssistant.travelInsights {
                TravelInsightsView(insight: insight)
            } else {
                // Input form for travel insights
                VStack(alignment: .leading, spacing: 12) {
                    Text("Get smart travel budget insights")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("Destination (e.g., Paris)", text: $travelDestination)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Budget", text: $travelBudget)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        generateTravelInsights()
                    } label: {
                        Label("Generate Insights", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(travelDestination.isEmpty || travelBudget.isEmpty)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemBackground).opacity(0.6))
                )
            }
        }
    }
    
    private var aiAlertRecommendationsSection: some View {
        AlertRecommendationsSectionView(
            history: history,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            activeRates: activeRates,
            onRecommendationTapped: handleAlertRecommendation
        )
    }
    
    // MARK: - AI Handler Methods
    
    private func handleAIConversionRequest(_ request: ConversionRequest) {
        // Apply the conversion request from AI
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            amount = String(request.amount)
            baseCurrency = request.baseCurrency
            targetCurrency = request.targetCurrency
        }
        
        recordRecent(request.baseCurrency)
        recordRecent(request.targetCurrency)
        haptic()
    }
    
    private func handleSmartSuggestion(_ suggestion: SmartSuggestion) {
        switch suggestion.action {
        case .quickPair(let base, let target):
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                baseCurrency = base
                targetCurrency = target
            }
            recordRecent(base)
            recordRecent(target)
            
        case .setAmount(let value):
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                amount = String(value)
            }
            
        case .showTravelCurrencies:
            // Navigate to tools tab
            break
            
        case .createAlert(let base, let target, let threshold):
            let newRule = CurrencyAlertRule(
                id: UUID(),
                base: base,
                target: target,
                threshold: threshold,
                direction: .above
            )
            var rules = alertRules
            rules.append(newRule)
            if let data = try? JSONEncoder().encode(rules) {
                alertRulesJSON = String(data: data, encoding: .utf8) ?? "[]"
            }
        }
        
        haptic()
    }
    
    private func handleAlertRecommendation(_ recommendation: AlertRecommendation) {
        let direction: CurrencyAlertRule.Direction = recommendation.type == .above ? .above : .below
        let newRule = CurrencyAlertRule(
            id: UUID(),
            base: baseCurrency,
            target: targetCurrency,
            threshold: recommendation.threshold,
            direction: direction
        )
        
        var rules = alertRules
        rules.append(newRule)
        if let data = try? JSONEncoder().encode(rules) {
            alertRulesJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
        
        toastMessage = "Alert added: \(recommendation.threshold)"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showToast = false }
        }
        
        haptic()
    }
    
    private func generateTravelInsights() {
        guard let budget = Double(travelBudget) else { return }
        
        Task {
            let currentRate = activeRates[targetCurrency] ?? 1.0 / (activeRates[baseCurrency] ?? 1.0)
            
            let insight = await aiAssistant.generateTravelInsights(
                destination: travelDestination,
                budgetInBaseCurrency: budget,
                baseCurrency: baseCurrency,
                destinationCurrency: targetCurrency,
                currentRate: currentRate
            )
            
            await MainActor.run {
                aiAssistant.travelInsights = insight
            }
        }
    }
    
    private func loadAISuggestions() {
        Task {
            // Convert conversion history to the format AI expects
            let suggestions = await aiAssistant.generateSmartSuggestions(
                basedOn: [],
                currentLocation: nil,
                timeOfDay: Date()
            )
            
            await MainActor.run {
                aiAssistant.smartSuggestions = suggestions
            }
        }
    }
}

// MARK: - Alerts Manager Sheet
private struct AlertsManagerView: View {
    var base: String
    var target: String
    var rules: [CurrencyAlertRule]
    var onSave: ([CurrencyAlertRule]) -> Void
    var onClose: () -> Void

    @State private var localRules: [CurrencyAlertRule] = []
    @State private var thresholdText: String = ""
    @State private var direction: CurrencyAlertRule.Direction = .below

    var body: some View {
        NavigationStack {
            List {
                Section("Existing Alerts") {
                    if localRules.isEmpty {
                        Text("No alerts yet").foregroundStyle(.secondary)
                    } else {
                        ForEach(localRules) { r in
                            HStack {
                                Text("\(r.base)→\(r.target)")
                                Spacer()
                                Text(String(format: "%.4f %@", r.threshold, r.direction == .above ? "▲" : "▼")).foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { idx in localRules.remove(atOffsets: idx) }
                    }
                }
                Section("Add Alert for \(base)→\(target)") {
                    HStack {
                        TextField("Threshold", text: $thresholdText).keyboardType(.decimalPad)
                        Picker("Direction", selection: $direction) {
                            Text("Above").tag(CurrencyAlertRule.Direction.above)
                            Text("Below").tag(CurrencyAlertRule.Direction.below)
                        }
                        .pickerStyle(.segmented)
                    }
                    Button("Add Alert") {
                        if let thr = Double(thresholdText.replacingOccurrences(of: ",", with: ".")) {
                            localRules.append(CurrencyAlertRule(id: UUID(), base: base, target: target, threshold: thr, direction: direction))
                            thresholdText = ""
                        }
                    }
                }
            }
            .navigationTitle("Alerts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { onClose() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { onSave(localRules); onClose() } }
            }
            .onAppear { localRules = rules }
        }
    }
}

// MARK: - Quick Pairs Manager
private struct QuickPairsManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var localPairs: [CurrencyQuickPair] = []
    var pairs: [CurrencyQuickPair]
    var onSave: ([CurrencyQuickPair]) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(localPairs.enumerated()), id: \.offset) { idx, pair in
                    HStack {
                        TextField("Base", text: Binding(get: { pair.base }, set: { localPairs[idx].base = $0 }))
                            .textInputAutocapitalization(.characters)
                        Text("→")
                        TextField("Target", text: Binding(get: { pair.target }, set: { localPairs[idx].target = $0 }))
                            .textInputAutocapitalization(.characters)
                    }
                }
                .onDelete { localPairs.remove(atOffsets: $0) }
                Button { localPairs.append(CurrencyQuickPair(base: "USD", target: "EUR")) } label: { Label("Add", systemImage: "plus") }
                    .accessibilityLabel(Text("Add a quick pair"))
            }
            .navigationTitle("Quick Pairs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { onSave(localPairs); dismiss() } }
            }
            .onAppear { localPairs = pairs }
        }
    }
}

// MARK: - Presets Manager
private struct PresetsManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var localPresets: [String] = []
    var presets: [String]
    var onSave: ([String]) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(localPresets.enumerated()), id: \.offset) { idx, val in
                    HStack {
                        TextField("Amount", text: Binding(get: { val }, set: { localPresets[idx] = $0 }))
                            .keyboardType(.decimalPad)
                        Spacer()
                    }
                }
                .onDelete { localPresets.remove(atOffsets: $0) }
                Button { localPresets.append("100") } label: { Label("Add", systemImage: "plus") }
                    .accessibilityLabel(Text("Add an amount preset"))
            }
            .navigationTitle("Amount Presets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { onSave(localPresets); dismiss() } }
            }
            .onAppear { localPresets = presets }
        }
    }
}

// MARK: - Math helpers
private func movingAverage(_ values: [Double], window: Int) -> [Double] {
    guard window > 1, values.count >= window else { return [] }
    var result: [Double] = []
    var sum: Double = values.prefix(window).reduce(0, +)
    result.append(sum / Double(window))
    for i in window..<values.count {
        sum += values[i] - values[i - window]
        result.append(sum / Double(window))
    }
    return result
}

// MARK: - Circle Ring Layout
struct CircleRing<Content: View>: View {
    let count: Int
    let radius: CGFloat
    let rotationOffset: Angle
    let content: (Int) -> Content

    init(count: Int, radius: CGFloat, rotationOffset: Angle = .degrees(0), @ViewBuilder content: @escaping (Int) -> Content) {
        self.count = count
        self.radius = radius
        self.rotationOffset = rotationOffset
        self.content = content
    }

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let base = Angle(degrees: (Double(index) / Double(max(count, 1))) * 360.0 - 90)
                let angle = base + rotationOffset
                content(index)
                    .position(
                        x: cos(CGFloat(angle.radians)) * radius + radius,
                        y: sin(CGFloat(angle.radians)) * radius + radius
                    )
            }
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}

// MARK: - Enhanced Currency Chip
struct CurrencyChip: View {
    let code: String
    var isSelected: Bool
    var showLabel: Bool
    var action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Enhanced circle with gradient and shadow
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.3),
                                    Color.accentColor.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color(.secondarySystemBackground),
                                    Color(.tertiarySystemBackground)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? Color.accentColor : Color(.separator).opacity(0.5),
                                    lineWidth: isSelected ? 3 : 1.5
                                )
                        )
                        .shadow(
                            color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.1),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: isSelected ? 4 : 2
                        )
                        .frame(width: 52, height: 52)
                    
                    Text(emojiFor(code: code))
                        .font(.title2)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }
                if showLabel {
                    Text(code)
                        .font(.caption2.weight(isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel(Text("Currency \(code)"))
        .accessibilityValue(Text(isSelected ? "Selected" : "Not selected"))
        .accessibilityAddTraits(.isButton)
    }

    private func emojiFor(code: String) -> String {
        switch code {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "JPY": return "🇯🇵"
        case "CAD": return "🇨🇦"
        case "AUD": return "🇦🇺"
        case "CHF": return "🇨🇭"
        case "CNY": return "🇨🇳"
        case "INR": return "🇮🇳"
        case "BRL": return "🇧🇷"
        case "ZAR": return "🇿🇦"
        case "SEK": return "🇸🇪"
        default: return "💱"
        }
    }
}

private extension View {
    func disclosureGroupStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.secondarySystemBackground).opacity(0.6),
                                Color(.tertiarySystemBackground).opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
            )
    }
}

private extension View {
    /// Ensures a minimum 44x44pt hit target per HIG
    func minTapTarget() -> some View {
        self
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}

fileprivate struct LinkedHashSet<Element: Hashable>: Sequence {
    private var order: [Element] = []
    private var set: Set<Element> = []

    init(_ elements: [Element] = []) {
        for e in elements { append(e) }
    }

    mutating func append(_ element: Element) {
        if !set.contains(element) {
            set.insert(element)
            order.append(element)
        }
    }

    mutating func insertAtFront(_ element: Element) {
        if set.contains(element) {
            order.removeAll { $0 == element }
        } else {
            set.insert(element)
        }
        order.insert(element, at: 0)
    }

    func prefix(_ maxLength: Int) -> ArraySlice<Element> { order.prefix(maxLength) }

    func makeIterator() -> IndexingIterator<[Element]> { order.makeIterator() }
}

// MARK: - Async Helper Views for AI Sections

struct RateTrendSectionView: View {
    let history: [ContentView.RatePoint]
    let baseCurrency: String
    let targetCurrency: String
    
    @ObservedObject private var aiAssistant = AIAssistantManager.shared
    @State private var prediction: RateTrendPrediction?
    
    var body: some View {
        Group {
            if let prediction = prediction {
                RateTrendView(
                    prediction: prediction,
                    baseCurrency: baseCurrency,
                    targetCurrency: targetCurrency
                )
            }
        }
        .task {
            guard !history.isEmpty else { return }
            let ratePoints = history.map { RateDataPoint(date: $0.date, rate: $0.value) }
            prediction = await aiAssistant.predictRateTrend(
                baseCurrency: baseCurrency,
                targetCurrency: targetCurrency,
                historicalRates: ratePoints
            )
        }
    }
}

struct AlertRecommendationsSectionView: View {
    let history: [ContentView.RatePoint]
    let baseCurrency: String
    let targetCurrency: String
    let activeRates: [String: Double]
    let onRecommendationTapped: (AlertRecommendation) -> Void
    
    @ObservedObject private var aiAssistant = AIAssistantManager.shared
    @State private var recommendations: [AlertRecommendation] = []
    
    var body: some View {
        Group {
            if !recommendations.isEmpty {
                AlertRecommendationsView(recommendations: recommendations) { recommendation in
                    onRecommendationTapped(recommendation)
                }
            }
        }
        .task {
            guard !history.isEmpty else { return }
            let ratePoints = history.map { RateDataPoint(date: $0.date, rate: $0.value) }
            let currentRate = activeRates[targetCurrency] ?? 1.0 / (activeRates[baseCurrency] ?? 1.0)
            
            recommendations = await aiAssistant.recommendAlerts(
                baseCurrency: baseCurrency,
                targetCurrency: targetCurrency,
                currentRate: currentRate,
                historicalRates: ratePoints
            )
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .preferredColorScheme(.light)
    }
}

