# Integration Guide - After Test Success

## Once SimpleAITest Works

If the test app successfully shows responses, follow these steps to integrate into your main app.

---

## Step 1: Verify Test Success

You should see:
- ✅ Green status indicator
- ✅ Successful responses to queries
- ✅ Console shows detailed logs
- ✅ Both "Basic Response" and "Structured Parse" work

---

## Step 2: Update AIAssistantView

Replace the query handling in `AIAssistantView.swift`:

### Find the sendMessage() task block and replace with:

```swift
Task {
    print("\n🚨 Sending message: '\(query)'")
    
    let token = UUID()
    currentTaskID = token
    
    // Check model availability
    let available = AIEngine_Clean.shared.isAvailable
    print("🤖 Model Available: \(available)")
    
    if !available {
        print("⚠️ Model unavailable: \(AIEngine_Clean.shared.availabilityDescription)")
        let errorMsg = ConversationMessage(
            text: "⚠️ AI not available\n\n\(AIEngine_Clean.shared.availabilityDescription)",
            isUser: false,
            timestamp: Date()
        )
        assistant.conversationHistory.append(errorMsg)
        return
    }
    
    // Try to get response
    if let response = await AIEngine_Clean.shared.respond(to: query) {
        guard currentTaskID == token else {
            print("⚠️ Task cancelled")
            return
        }
        
        let aiMessage = ConversationMessage(
            text: response,
            isUser: false,
            timestamp: Date()
        )
        assistant.conversationHistory.append(aiMessage)
        print("✅ Response added to conversation")
    } else {
        print("❌ No response from model")
        let errorMsg = ConversationMessage(
            text: "Sorry, I couldn't process that. The model may be unavailable.",
            isUser: false,
            timestamp: Date()
        )
        assistant.conversationHistory.append(errorMsg)
    }
}
```

---

## Step 3: Add Structured Parsing (Optional)

If you want to parse queries into structured data:

```swift
// Instead of respond(to:), use parseQuery(_:)
if let parsed = await AIEngine_Clean.shared.parseQuery(query) {
    // Use parsed.intent to route to different handlers
    switch parsed.intent.lowercased() {
    case "conversion":
        // Handle conversion
        if let from = parsed.fromCurrency,
           let to = parsed.toCurrency,
           let amount = parsed.amount {
            // Trigger conversion with from, to, amount
        }
        
    case "info":
        // Show the message
        let msg = ConversationMessage(text: parsed.message, isUser: false, timestamp: Date())
        assistant.conversationHistory.append(msg)
        
    default:
        // General response
        let msg = ConversationMessage(text: parsed.message, isUser: false, timestamp: Date())
        assistant.conversationHistory.append(msg)
    }
}
```

---

## Step 4: Update App Entry Point

Change `currency_converterApp.swift` back to production:

```swift
import SwiftUI

@main
struct currency_converterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()  // Back to your main app
        }
    }
}
```

---

## Step 5: Add Pre-warming

In your main view's `.task` or `.onAppear`:

```swift
.task {
    AIEngine_Clean.shared.prewarm()
}
```

---

## Step 6: Remove Old Code (Optional)

Once everything works with `AIEngine_Clean`:

1. **Keep for reference:**
   - `AIEngine.swift` (old version)
   - `CurrencyAIModels.swift` (old models)

2. **Or delete if confident:**
   - Move to backup folder
   - Remove from Xcode project

3. **Clean up:**
   - Remove unused imports
   - Remove unused methods
   - Simplify error handling

---

## Step 7: Test Full App

Test these scenarios:

### Test 1: Basic Questions
```
"What is Mexico's currency?"
"What currency does Japan use?"
```

### Test 2: Conversions
```
"100 USD to EUR"
"How much is 50 dollars in pesos?"
```

### Test 3: Error Cases
```
"asdfasdf"  → Should handle gracefully
""          → Should be disabled
```

### Test 4: Multiple Messages
```
Message 1: "What is Japan's currency?"
Message 2: "What about Mexico?"
Message 3: "100 USD to EUR"
```

---

## Advantages of Clean Implementation

### ✅ Simpler
- Less code to maintain
- Clearer logic flow
- Easier to debug

### ✅ More Reliable
- Follows Apple's patterns exactly
- Proper error handling
- Clear availability checks

### ✅ Better Performance
- Pre-warming support
- Greedy sampling
- Minimal overhead

### ✅ Easier to Extend
- Add new methods easily
- Clear structure
- Well documented

---

## Extending the Clean Implementation

### Add Streaming:

```swift
func streamResponse(to query: String, onUpdate: @escaping (String) -> Void) async {
    guard isAvailable else { return }
    
    for try await snapshot in session.streamResponse(to: query) {
        onUpdate(snapshot.content)
    }
}
```

### Add Tools:

```swift
let rateTool = ExchangeRateTool()
let session = LanguageModelSession(
    tools: [rateTool],
    instructions: instructions
)
```

### Add Few-Shot Examples:

```swift
let prompt = Prompt {
    "Convert currency: \(query)"
    "Here's an example:"
    SimpleParse.example
}
```

---

## Troubleshooting Integration

### Issue: Old code conflicts

**Solution:** Rename classes temporarily:
```swift
// Old: class AIEngine
// New: class AIEngine_Old

// Use AIEngine_Clean everywhere
```

### Issue: Type mismatches

**Solution:** Update model types:
```swift
// Old: CurrencyQueryParse
// New: SimpleParse

// Or keep both and convert between them
```

### Issue: Missing features

**Solution:** Add incrementally:
1. Start with basic text generation
2. Add structured parsing
3. Add streaming
4. Add tools

Don't try to add everything at once!

---

## Rollback Plan

If integration causes issues:

### Quick Rollback:
```swift
// In currency_converterApp.swift
WindowGroup {
    SimpleAITest()  // Go back to test view
}
```

### Full Rollback:
1. Revert to old `AIEngine.swift`
2. Comment out `AIEngine_Clean.swift`
3. Keep for future attempt

---

## Success Criteria

Integration is successful when:

- ✅ App builds without errors
- ✅ AI Chat shows responses
- ✅ Console shows clear logs
- ✅ No crashes or hangs
- ✅ Availability properly detected
- ✅ Error messages are helpful

---

## Next Steps After Integration

### 1. Add Your Custom Logic
- Intent routing
- Conversion handling
- Context awareness
- Special features

### 2. Improve UI
- Better loading states
- Nicer error messages
- Progress indicators
- Animations

### 3. Optimize
- Add caching
- Improve prompts
- Add examples
- Fine-tune instructions

### 4. Test Thoroughly
- Edge cases
- Error conditions
- Performance
- User experience

---

## Summary

✅ **Test first** - Verify Foundation Models works  
✅ **Integrate slowly** - One piece at a time  
✅ **Keep it simple** - Don't over-engineer  
✅ **Test thoroughly** - Every feature  
✅ **Can rollback** - If needed  

**Start with the test, then integrate step by step!** 🚀

