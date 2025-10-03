# 🔒 App Store Privacy Guide for Tool Calling

## TL;DR

**YES, tool calling with network requests requires privacy disclosures for App Store approval.**

**Solution:** Make network requests optional + add privacy manifest.

---

## The Privacy Issue

### Current Implementation:

```swift
// LiveCurrencyRateTool makes network requests
let urlString = "https://api.exchangerate.host/latest?base=USD&symbols=EUR"
```

**Privacy concerns:**
- ❌ Third-party API receives requests
- ❌ User's IP address exposed
- ❌ Request metadata could be logged
- ✅ No personal data sent (just currency codes)

---

## App Store Requirements

### 1. Privacy Manifest (Required for iOS 17+)

**File:** `PrivacyInfo.xcprivacy` ✅ **Created**

**Declares:**
- Network access usage
- Reasons for API access
- Data collection practices

### 2. Privacy Nutrition Labels

**In App Store Connect:**

```
Data Used to Track You: NO

Data Linked to You: NO

Data Not Linked to You: 
  ☑️ Product Interaction
      "Currency queries sent to rate provider API"
```

### 3. Privacy Policy

**Must include:**
- Statement about exchangerate.host API usage
- What data is sent (currency codes only)
- Link to third-party privacy policy
- User's rights and choices

---

## Recommended Solution

### Hybrid Approach: Background Cache + Optional Real-Time

**1. Default Behavior (Privacy-Friendly):**
```swift
// Fetch rates in background (once per day)
// Cache locally
// Tools use cached rates (no network during queries)
```

**2. Optional Real-Time (User Opts In):**
```swift
// Settings toggle: "Use Real-Time Rates"
// User explicitly consents
// Network requests during queries
```

**3. Offline Fallback:**
```swift
// If no network or user declines
// Use reference rates from system instructions
```

---

## Implementation Changes Needed

### Change 1: Add Privacy Manifest

**✅ Done:** `PrivacyInfo.xcprivacy` created

**Add to Xcode:**
1. Drag `PrivacyInfo.xcprivacy` to your project
2. Ensure it's in the app target
3. It will be included in the app bundle

### Change 2: Add User Settings

```swift
// New Settings view
struct PrivacySettingsView: View {
    @AppStorage("allowLiveRates") private var allowLiveRates = false
    
    var body: some View {
        Form {
            Section(header: Text("Exchange Rates")) {
                Toggle("Use Real-Time Rates", isOn: $allowLiveRates)
                
                Text("""
                    When enabled, currency queries are sent to our rate \
                    provider API for the most accurate, up-to-date rates.
                    
                    When disabled, approximate rates are used (updated daily).
                    """)
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Section(header: Text("Privacy")) {
                Link("Privacy Policy", destination: URL(string: "https://yourwebsite.com/privacy")!)
                Link("Rate Provider Privacy", destination: URL(string: "https://exchangerate.host/privacy")!)
            }
        }
        .navigationTitle("Privacy Settings")
    }
}
```

### Change 3: Respect User Settings

```swift
// In CurrencyAIEngine.swift
private var allowNetworkRequests: Bool {
    UserDefaults.standard.bool(forKey: "allowLiveRates")
}

private func createCurrencyTools() -> [any Tool] {
    var tools: [any Tool] = []
    
    #if canImport(FoundationModels)
    if allowNetworkRequests {
        // User opted in - use real-time tool
        tools.append(LiveCurrencyRateTool())
    } else {
        // Use cached rates tool (no network)
        tools.append(CachedCurrencyRateTool())
    }
    #endif
    
    return tools
}
```

### Change 4: First Launch Disclosure

```swift
// Show on first launch
struct PrivacyOnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("allowLiveRates") private var allowLiveRates = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Your Privacy Matters")
                .font(.title)
                .bold()
            
            Text("""
                This app uses on-device AI powered by Apple Intelligence. \
                All processing happens on your device.
                
                For the most accurate exchange rates, we can optionally \
                fetch real-time data from exchangerate.host. This requires \
                a network connection and sends currency codes (like USD, EUR) \
                to their API.
                
                No personal information is collected or shared.
                """)
            .multilineTextAlignment(.center)
            .padding()
            
            VStack(spacing: 12) {
                Button("Use Real-Time Rates") {
                    allowLiveRates = true
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                
                Button("Use Offline Estimates") {
                    allowLiveRates = false
                    isPresented = false
                }
                .buttonStyle(.bordered)
            }
            
            Link("Privacy Policy", destination: URL(string: "https://yourwebsite.com/privacy")!)
                .font(.caption)
        }
        .padding()
    }
}
```

---

## Privacy Policy Template

```markdown
# Privacy Policy for [Your Currency App]

Last updated: [Date]

## Data Collection

We do NOT collect any personal information.

## Exchange Rate Data

Our app can optionally fetch real-time exchange rates from exchangerate.host. 
When this feature is enabled:

- Currency codes (e.g., "USD", "EUR") are sent to exchangerate.host API
- No personal information is included in these requests
- Your IP address may be logged by the API provider
- See exchangerate.host's privacy policy: https://exchangerate.host/privacy

You can disable this feature in Settings and use offline estimates instead.

## On-Device AI

All AI processing uses Apple's on-device Foundation Models. Your queries 
and conversations:

- Are processed entirely on your device
- Are NEVER sent to our servers or third parties
- Are NOT logged or stored by us
- Remain completely private

## Third-Party Services

- **exchangerate.host** (optional): Provides real-time exchange rates
- **Apple Foundation Models**: On-device AI (100% private)

## Your Choices

You can:
- Disable real-time rates in Settings
- Use the app entirely offline
- Delete the app at any time

## Changes to This Policy

We may update this policy. Continued use constitutes acceptance.

## Contact

Questions? Email: support@yourapp.com
```

---

## App Store Connect Setup

### Privacy Nutrition Labels:

**Section 1: Data Used to Track You**
```
☐ Data Used to Track You
Answer: NO
```

**Section 2: Data Linked to You**
```
☐ Data Linked to You
Answer: NO
```

**Section 3: Data Not Linked to You**

```
☑️ Product Interaction
   ☑️ Product Interaction
       Purpose: App Functionality
       
   Description:
   "Currency queries (e.g., USD, EUR) are sent to our rate provider 
    API to fetch real-time exchange rates. This feature is optional 
    and can be disabled in Settings."
```

---

## Review Guidelines Compliance

### Guideline 5.1.1 (Data Collection)

**Requirement:** "Apps must have a privacy policy"

**Your compliance:**
- ✅ Privacy policy created
- ✅ Link in App Store listing
- ✅ Link in app settings

### Guideline 5.1.2 (Data Use)

**Requirement:** "Be transparent about data use"

**Your compliance:**
- ✅ First launch disclosure
- ✅ Settings toggle with explanation
- ✅ Privacy nutrition labels accurate

### Guideline 2.5.14 (Location Services)

**Requirement:** "Apps transmitting location must have privacy policy"

**Your compliance:**
- ✅ IP address can reveal location
- ✅ Privacy policy discloses API usage
- ✅ User can opt out

---

## Common App Review Rejections

### Rejection 1: Unexpected Network Activity

**Issue:**
> "Your app makes network requests without user knowledge"

**Prevention:**
- ✅ First launch disclosure
- ✅ User opt-in toggle
- ✅ Clear UI indication when fetching data

### Rejection 2: Missing Privacy Manifest

**Issue:**
> "Your app is missing required privacy manifest"

**Prevention:**
- ✅ PrivacyInfo.xcprivacy included
- ✅ Declares network access reasons

### Rejection 3: Inaccurate Privacy Labels

**Issue:**
> "Privacy nutrition labels don't match actual data collection"

**Prevention:**
- ✅ Accurately declared "Product Interaction"
- ✅ Clearly stated it's currency codes only
- ✅ No tracking or personal data

---

## Alternative: Fully Private Implementation

### If you want to avoid ALL complexity:

**Remove network tools entirely:**

```swift
// In CurrencyAIEngine.swift
private func createCurrencyTools() -> [any Tool] {
    return [] // No tools with network access
}

// Update system instructions with more reference rates
let instructions = Instructions {
    """
    REFERENCE RATES (updated with app releases):
    • [Include 50+ currencies]
    • Last updated: [Date]
    """
}
```

**Benefits:**
- ✅ 100% private
- ✅ No privacy manifest complexity
- ✅ No App Store privacy concerns
- ✅ Works offline
- ✅ Fastest (no network latency)

**Drawbacks:**
- ❌ Less accurate (rates can be stale)
- ❌ Need app updates to refresh rates

---

## Summary

### Privacy Complexity: **Medium**

**Required:**
1. ✅ Privacy manifest (PrivacyInfo.xcprivacy)
2. ✅ Privacy policy
3. ✅ Accurate nutrition labels

**Recommended:**
1. ✅ User opt-in for network requests
2. ✅ First launch disclosure
3. ✅ Settings toggle

**Optional (Safest):**
1. ✅ Remove network tools entirely
2. ✅ 100% on-device only

---

## My Recommendation

**For App Store approval:**

1. **Add PrivacyInfo.xcprivacy** ✅ (Done)
2. **Create privacy policy** (Use template above)
3. **Add user settings** for network opt-in
4. **Show first launch disclosure**
5. **Update App Store Connect** with accurate labels

**This gives you:**
- ✅ App Store compliant
- ✅ User trust (transparency)
- ✅ Flexibility (real-time or offline)
- ✅ No surprises in review

---

## Want Me To Implement?

I can implement the recommended solution:

1. ✅ Privacy manifest (done)
2. ⏳ Privacy settings view
3. ⏳ First launch disclosure
4. ⏳ Cached rates tool (no network during queries)
5. ⏳ Background rate updates
6. ⏳ User opt-in for real-time

**Say "implement privacy controls" and I'll do it!**

---

**Bottom Line:** Tool calling with network requests is fine for App Store, 
but requires proper privacy disclosures and user consent. With the privacy 
manifest and user controls, you'll have no issues getting approved.

