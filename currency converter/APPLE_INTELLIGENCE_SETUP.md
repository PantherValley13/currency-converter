# Apple Intelligence Setup Guide

## The Issue

Your AI Assistant is showing this message for every query:
```
I'm having trouble understanding that. 
Could you try asking differently? For example:
• 'What is Japan's currency?'
• '100 USD to EUR'
• 'How much is 50 dollars in pesos?'
```

This happens because the **on-device LLM (Apple Intelligence) is not available** on your device.

---

## Why It Happens

The app now uses Apple's Foundation Models (Apple Intelligence) for 100% LLM-driven responses. When the model isn't available, `parseQuery()` returns `nil`, triggering the fallback message.

---

## Requirements for Apple Intelligence

### Minimum Requirements

#### iPhone/iPad:
- **iPhone 15 Pro** or **iPhone 15 Pro Max** (minimum)
- **iPhone 16** or later (all models)
- **iOS 18.1** or later

#### Mac:
- **M1** chip or later (M1, M2, M3, M4)
- **macOS Sequoia 15.1** or later

#### Not Supported:
- ❌ iPhone 15 (non-Pro)
- ❌ iPhone 14 or earlier
- ❌ Intel-based Macs
- ❌ iPad (currently limited support)

---

## How to Enable Apple Intelligence

### Step 1: Check Your Device

1. Go to **Settings** → **About**
2. Check your **Model** (iPhone 15 Pro, iPhone 16, etc.)
3. Check your **Software Version** (must be 18.1 or later)

### Step 2: Update to iOS 18.1+

If you're on iOS 18.0 or earlier:
1. Go to **Settings** → **General** → **Software Update**
2. Download and install **iOS 18.1** or later
3. Restart your device

### Step 3: Enable Apple Intelligence

1. Go to **Settings**
2. Scroll down and tap **Apple Intelligence & Siri**
3. Toggle **ON** the "Apple Intelligence" switch
4. Follow the prompts to download the on-device model
   - This can take **several minutes to hours** depending on your connection
   - The model is ~2-4 GB
5. Wait for "Ready" status

### Step 4: Set Language to English (US)

Apple Intelligence currently only works with English (US):
1. **Settings** → **General** → **Language & Region**
2. Set **iPhone Language** to **English (United States)**
3. Set **Region** to **United States** (optional but recommended)

---

## How to Check Status in the App

### Run the App and Check Console Logs

When you send a message to the AI Assistant, check the Xcode console:

**If Model is Available:**
```
🤖 Model Available: true
🧠 AIEngine: LLM Query Parsing (Structured Output)
📝 Query: "What is Japan's currency?"
✅ Parsed Successfully!
```

**If Model is NOT Available:**
```
🤖 Model Available: false
⚠️  Model Status: Enable Apple Intelligence in Settings to use on-device AI
⚠️  Model Not Available - Cannot Parse
❌ LLM parsing failed completely
🎯 Reason: On-device model not available
```

---

## New Error Message (After Fix)

After my changes, the app will now show a **helpful error message** instead of the generic fallback:

```
⚠️ AI features require Apple Intelligence

Enable Apple Intelligence in Settings to use on-device AI

Please check:
• iOS 18.1+ or macOS 15.1+
• Apple Intelligence enabled in Settings
• Compatible device (iPhone 15 Pro or later, M1+ Mac)
```

---

## Testing Without Apple Intelligence

If you can't enable Apple Intelligence, you have two options:

### Option A: Use a Fallback Service (Recommended for Production)

Modify `AIEngine.swift` to fall back to a cloud API when the model isn't available:

```swift
func parseQuery(_ query: String, context: String? = nil) async -> CurrencyQueryParse? {
    #if canImport(FoundationModels)
    guard isAvailable else {
        // Fall back to cloud API
        return await parseWithCloudAPI(query, context: context)
    }
    // Use on-device model
    ...
    #else
    return await parseWithCloudAPI(query, context: context)
    #endif
}

private func parseWithCloudAPI(_ query: String, context: String?) async -> CurrencyQueryParse? {
    // Call OpenAI, Anthropic, or your own backend
    // Return structured CurrencyQueryParse
}
```

### Option B: Mock the Model for Testing

Add a test mode that returns mock parsed results:

```swift
// In AIEngine.swift
var testMode: Bool = false

func parseQuery(_ query: String, context: String? = nil) async -> CurrencyQueryParse? {
    if testMode {
        return mockParse(query)
    }
    // ... existing code
}

private func mockParse(_ query: String) -> CurrencyQueryParse {
    // Simple pattern matching for testing
    if query.lowercased().contains("japan") && query.lowercased().contains("currency") {
        return CurrencyQueryParse(
            amount: nil,
            fromCurrency: nil,
            toCurrency: nil,
            intent: .currencyInfo,
            isComplete: true,
            responseMessage: "Japan's currency is the Japanese Yen (JPY)."
        )
    }
    // ... more patterns
}
```

---

## What Changed in the Code

### AIAssistantView.swift

**Added model availability check:**
```swift
// Check if the model is available first
let modelAvailable = AIEngine.shared.isAvailable
print("🤖 Model Available: \(modelAvailable)")
if !modelAvailable {
    print("⚠️  Model Status: \(AIEngine.shared.availabilityDescription)")
}
```

**Better fallback message:**
```swift
if !AIEngine.shared.isAvailable {
    fallbackMessage = "⚠️ AI features require Apple Intelligence\n\n..."
} else {
    fallbackMessage = "I'm having trouble understanding that. Could you try..."
}
```

---

## Troubleshooting

### "Model is downloading or not ready yet"

**Solution:** Wait for the download to complete
- Go to **Settings** → **Apple Intelligence & Siri**
- Check download progress
- Can take 30 minutes to 2 hours on slow connections

### "Device not eligible for Apple Intelligence"

**Solution:** Your device doesn't support it
- Check device requirements above
- Consider using Option A (cloud fallback) for production

### "Apple Intelligence not enabled"

**Solution:** Enable it
- Follow Step 3 above
- Make sure iOS 18.1+ is installed

### Model available but still failing

**Check these:**
1. **Language:** Must be English (US)
2. **Region:** Should be United States
3. **Siri:** Enable Siri (Apple Intelligence uses same backend)
4. **Restart:** Restart device after enabling
5. **Wait:** Model initialization can take 5-10 minutes after enabling

---

## Verification Steps

### 1. Check Xcode Console
Run the app and send a test message. Look for:
```
🤖 Model Available: true
```

### 2. Test Basic Query
Try: "What is Japan's currency?"

**Expected Success:**
```
📊 LLM Parse Result:
├─ Intent: Currency Information
├─ Complete: true
💬 Response: "Japan's currency is the Japanese Yen (JPY)."
```

**Expected Failure (model unavailable):**
```
⚠️ AI features require Apple Intelligence...
```

### 3. Test Conversion
Try: "100 USD to EUR"

**Expected Success:**
```
📊 LLM Parse Result:
├─ Intent: Conversion
├─ Complete: true
├─ From: USD
├─ To: EUR
└─ Amount: 100.0
🔔 Triggering Conversion Action
```

---

## Summary

✅ **Code is correct** - All LLM integration is properly implemented  
⚠️ **Apple Intelligence required** - On-device model must be available  
🔧 **Better error handling** - App now explains why it's not working  
📱 **Device requirements** - iPhone 15 Pro+, M1+ Mac, iOS 18.1+  

The fix I just implemented will now show a **clear error message** explaining that Apple Intelligence needs to be enabled, instead of the confusing "I'm having trouble understanding" message.

Test it again and check the console logs to see the exact status! 🚀

