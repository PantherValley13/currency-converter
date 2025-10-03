# 🔬 LLM Debug Guide

## What We've Set Up

I've created a **comprehensive LLM debugger** to diagnose the on-device model:

### New File: `LLMDebugView.swift`

A full-featured debug interface that:
- ✅ Checks model availability
- ✅ Shows detailed status information
- ✅ Tests queries with real-time feedback
- ✅ Logs all responses and errors
- ✅ Provides quick test buttons
- ✅ Shows performance metrics

---

## 🚀 How to Use

### 1. Run the App
The app is now configured to launch the **LLM Debugger** automatically.

In Xcode, press:
```
Cmd+R
```

### 2. Check Model Status
Look at the **"🔍 Model Status"** section at the top:

**If Available:**
```
Available:     ✅ YES
Description:   AI currency assistant ready
Raw:           available
```

**If NOT Available:**
```
Available:     ❌ NO
Description:   Device not eligible for Apple Intelligence
                     (or other reason)
Raw:           unavailable(reason)
```

### 3. Run Tests

**Option A - Quick Tests:**
Tap any of the quick test buttons:
- "Simple Conversion" - Tests "100 USD to EUR"
- "Currency Info" - Tests "What is Argentina's currency?"
- "Travel Advice" - Tests "I'm going to Tokyo with $2000"

**Option B - Custom Query:**
1. Enter your own query in the text field
2. Tap "Run Test"
3. Watch the debug log populate

### 4. Review Results

**Debug Log Shows:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔬 LLM DIAGNOSTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Timestamp: ...
📱 OS: iOS 18.1 (or macOS 15.1)
💻 Device: ...

🤖 Model Check:
├─ Available: ✅
├─ Status: AI currency assistant ready
└─ Raw: available
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🧪 TEST STARTED
📝 Query: "What is Japan's currency?"
⏱️  Start: ...
🚀 Sending query to CurrencyAIEngine...
✅ Response received!
⏱️  Duration: 1.23s

📊 RESPONSE DETAILS:
├─ Title: Japanese Yen (JPY)
├─ Type: CurrencyInfo
├─ Answer Length: 150 chars
└─ Full Answer:
   Japan uses the Japanese Yen (JPY), symbol ¥...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔍 What to Look For

### ✅ Success Indicators

1. **Model Available = YES**
   - Status says "AI currency assistant ready"
   - Quick test buttons are enabled
   - Raw availability is "available"

2. **Test Completes**
   - Shows "✅ Response received!"
   - Duration is 0.5-3 seconds
   - Full answer appears

3. **Response Has Data**
   - Title is populated
   - Query type is classified
   - Answer makes sense

### ❌ Problem Indicators

1. **Model NOT Available**
   ```
   Available: ❌ NO
   Description: Device not eligible for Apple Intelligence
   ```
   
   **Solutions:**
   - Check device (need iPhone 15 Pro+ or M1+ Mac)
   - Check OS version (need iOS 18.1+ or macOS 15.1+)
   - Enable Apple Intelligence in Settings

2. **"unavailable(appleIntelligenceNotEnabled)"**
   ```
   Raw: unavailable(appleIntelligenceNotEnabled)
   ```
   
   **Solution:**
   - Go to Settings → Apple Intelligence & Siri
   - Enable Apple Intelligence

3. **"unavailable(modelNotReady)"**
   ```
   Raw: unavailable(modelNotReady)
   ```
   
   **Solution:**
   - Model is downloading
   - Wait a few minutes
   - Check internet connection
   - Restart device

4. **Query Returns NIL**
   ```
   ❌ No response received
   ```
   
   **Possible causes:**
   - Model crashed
   - Memory issue
   - Try simpler query
   - Check Xcode console for errors

---

## 🧪 Recommended Test Sequence

1. **Check Availability First**
   - On app launch, diagnostics run automatically
   - Verify "Available: ✅ YES"

2. **Test Simple Query**
   - Tap "Simple Conversion"
   - Should respond in 1-2 seconds
   - Should show conversion details

3. **Test Currency Info**
   - Tap "Currency Info"
   - Should return currency name and info

4. **Test Travel Advice**
   - Tap "Travel Advice"
   - Should show destination and budget breakdown

5. **Test Custom Query**
   - Enter: "Is the Euro stronger than the Dollar?"
   - Should classify as comparison/general
   - Should give intelligent answer

---

## 📊 Performance Benchmarks

**Normal Performance:**
- First query: 1-3 seconds (cold start)
- Subsequent queries: 0.5-1.5 seconds (warm)
- Structured output parsing: +0.1-0.3s

**Slow Performance Indicators:**
- >5 seconds: Model might be struggling
- >10 seconds: Likely a problem
- Timeout: Model unavailable or crashed

---

## 🐛 Common Issues & Fixes

### Issue 1: "Device not eligible"
**Problem:** Your device doesn't support Apple Intelligence
**Fix:** Need iPhone 15 Pro or later, or M1+ Mac

### Issue 2: "Apple Intelligence not enabled"
**Problem:** Feature is disabled in Settings
**Fix:** Settings → Apple Intelligence & Siri → Enable

### Issue 3: "Model not ready"
**Problem:** Model is downloading or not installed
**Fix:** Wait for download, ensure stable internet

### Issue 4: Model available but no response
**Problem:** Model crashes or fails silently
**Fix:** 
- Check Xcode console for errors
- Try simpler query
- Restart app
- Clean build (Cmd+Shift+K)

### Issue 5: Gibberish responses
**Problem:** Model hallucinating or instructions unclear
**Fix:**
- Check `CurrencyAIEngine.swift` instructions
- Try different query phrasing
- Check few-shot examples

---

## 📱 Device Compatibility Check

### ✅ Compatible Devices

**iPhone:**
- iPhone 15 Pro
- iPhone 15 Pro Max
- iPhone 16 (all models)
- Future models

**Mac:**
- MacBook Air (M1, M2, M3)
- MacBook Pro (M1, M2, M3)
- iMac (M1, M3)
- Mac mini (M1, M2)
- Mac Studio (M1, M2)
- Mac Pro (M2)

**iPad:**
- iPad Pro (M1, M2, M4)
- iPad Air (M1, M2)

### ❌ NOT Compatible

- iPhone 15 (non-Pro)
- iPhone 14 and earlier
- Intel Macs
- iPad (non-M series)

---

## 🔧 Advanced Debugging

### Check Xcode Console

While running tests, watch Xcode console for:
```
🔧 CurrencyAIEngine: Initializing
📝 Creating LanguageModelSession with currency expertise
✅ Session Created Successfully

🧪 TEST STARTED
📝 Query: "..."
🚀 Sending query to CurrencyAIEngine...
✅ Response received!
```

### Common Console Errors

1. **"FoundationModels not found"**
   - OS too old (need iOS 18.1+)
   - Update to latest beta

2. **"Model unavailable"**
   - See availability checks above

3. **"Failed to generate response"**
   - Model crashed
   - Query too complex
   - Memory issue

---

## 📝 After Debugging

Once you confirm the model is working:

1. **Switch back to production app:**
   ```swift
   // In currency_converterApp.swift
   var body: some Scene {
       WindowGroup {
           ContentView()  // Uncomment this
           // LLMDebugView()  // Comment this out
       }
   }
   ```

2. **Or keep debug available:**
   - Add a debug tab in ContentView
   - Or add a hidden gesture to open debugger

---

## ✅ Success Checklist

- [ ] App launches without errors
- [ ] Diagnostics show "Available: ✅ YES"
- [ ] Status says "AI currency assistant ready"
- [ ] Quick tests return responses in <3s
- [ ] Response answers make sense
- [ ] Structured data is populated (conversion, travel, etc.)
- [ ] Multiple queries work consecutively
- [ ] Performance is consistent

---

## 🆘 Still Having Issues?

If the debugger shows the model is NOT available:

1. **Verify your setup:**
   - OS version: iOS 18.1+ or macOS 15.1+
   - Device: Apple Intelligence compatible
   - Settings: Apple Intelligence enabled

2. **Check Apple's status:**
   - Some regions may not support Apple Intelligence yet
   - Some beta versions may have bugs

3. **Try a simulator:**
   - Xcode simulator with iOS 18.1+
   - May work better than physical device for testing

4. **File a Radar:**
   - If you meet all requirements but it still doesn't work
   - Use Feedback Assistant to report to Apple

---

**The debug view is now running! Press Cmd+R in Xcode to test.** 🔬

