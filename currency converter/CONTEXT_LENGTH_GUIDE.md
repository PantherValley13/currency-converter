# 📏 Context Length - How to Increase It

## 📊 Current Context Limits

**Right now, the AI remembers:**
- **Last 3 conversation exchanges** (6 messages total)
- Each exchange = 1 user question + 1 AI response

**Example:**
```
Exchange 1: "What is Japan's currency?" → "Japan uses the Yen..."
Exchange 2: "How much is 100 USD?" → "100 USD ≈ 14,700 JPY..."
Exchange 3: "What about 200?" → "200 USD ≈ 29,400 JPY..."

Exchange 4+: [NOT remembered - too old]
```

---

## 🎯 Current Token Budget

**Why only 3 exchanges?**

The on-device model has token limits:
- **Input limit:** ~2000-4000 tokens
- **Output limit:** ~500-1000 tokens

**Current usage per query:**
```
System instructions:    400 tokens
Context (3 exchanges):  200 tokens
Current query:           50 tokens
Reserved for response:  500 tokens
─────────────────────────────────
TOTAL:                 1150 tokens (~50% of limit)
```

**Good news:** We have **plenty of headroom!** 🎉

---

## ✅ YES - You Can Increase Context!

**Safe options:**

| Context Size | Token Usage | Memory | Risk | Recommendation |
|--------------|-------------|--------|------|----------------|
| **3 exchanges** | ~1150 tokens | Short-term | ✅ Very safe | Current (default) |
| **5 exchanges** | ~1350 tokens | Medium-term | ✅ Safe | **Recommended** |
| **7 exchanges** | ~1550 tokens | Long-term | ✅ Safe | Good for complex conversations |
| **10 exchanges** | ~1850 tokens | Very long | ⚠️ Risky | May hit limits |
| **15+ exchanges** | ~2200+ tokens | Maximum | ❌ Dangerous | Will likely fail |

**My recommendation: 5-7 exchanges** - Perfect balance!

---

## 🔧 How to Increase Context

### Option 1: Quick Change (5 Exchanges)

**File: `AIAssistantView.swift`**

**Change line 345 from:**
```swift
// Limit to last 3 exchanges to avoid token overflow
if history.count >= 3 {
    break
}
```

**To:**
```swift
// Limit to last 5 exchanges (increased context)
if history.count >= 5 {
    break
}
```

**Change line 351 from:**
```swift
return Array(history.prefix(3))
```

**To:**
```swift
return Array(history.prefix(5))
```

**File: `CurrencyAIEngine.swift`**

**Change line 121 from:**
```swift
let recentHistory = conversationHistory.suffix(3)
```

**To:**
```swift
let recentHistory = conversationHistory.suffix(5)
```

**Done!** Now remembers last 5 exchanges instead of 3.

---

### Option 2: Configurable Context (Advanced)

**Make it configurable so you can adjust anytime:**

**1. Add a configuration variable:**

```swift
// In AIAssistantView.swift at the top
private let maxContextExchanges = 5  // Easy to change!
```

**2. Use it in the function:**

```swift
// Line 345
if history.count >= maxContextExchanges {
    break
}

// Line 351
return Array(history.prefix(maxContextExchanges))
```

**3. In CurrencyAIEngine.swift:**

```swift
// Add at top of class
private let maxContextExchanges = 5

// Use in answerQuery
let recentHistory = conversationHistory.suffix(maxContextExchanges)
```

**Benefit:** Change one number to adjust context length!

---

### Option 3: Smart Context Length (Adaptive)

**Automatically adjust based on query complexity:**

```swift
private func extractConversationHistory(for query: String) -> [(userQuery: String, aiResponse: String)] {
    // Determine context length based on query
    let maxExchanges: Int
    
    if query.lowercased().contains("explain") || 
       query.lowercased().contains("tell me about") ||
       query.count > 50 {
        maxExchanges = 7  // More context for complex queries
    } else if query.lowercased().contains("what") ||
              query.lowercased().contains("how much") {
        maxExchanges = 3  // Less context for simple questions
    } else {
        maxExchanges = 5  // Default
    }
    
    // ... rest of function using maxExchanges
}
```

**Smart!** Adapts context to query complexity.

---

## 📊 Impact of Different Context Lengths

### 3 Exchanges (Current):

**Pros:**
- ✅ Very safe from token limits
- ✅ Fast processing
- ✅ Good for simple Q&A

**Cons:**
- ❌ Short memory
- ❌ Forgets older topics quickly

**Example:**
```
Q1: "What is Japan's currency?"
Q2: "How much is 100 USD?"
Q3: "What about 200?"
Q4: "And 300?" 
    → Still remembers Japan ✅

Q5: "What about 400?"
    → Q1 forgotten, might lose Japan context ❌
```

---

### 5 Exchanges (Recommended):

**Pros:**
- ✅ Still very safe
- ✅ Better memory
- ✅ Handles multi-step conversations
- ✅ Only +200 tokens

**Cons:**
- ❌ Slightly more token usage (still safe)

**Example:**
```
Q1: "What is Japan's currency?"
Q2: "How much is 100 USD?"
Q3: "What about 200?"
Q4: "And 300?"
Q5: "What about 400?"
Q6: "And 500?"
    → Still remembers Japan through Q6 ✅

Q7: "What about 600?"
    → Q1-Q2 forgotten, but Q3-Q6 remembered ✅
```

---

### 7 Exchanges (Extended):

**Pros:**
- ✅ Long conversation memory
- ✅ Great for complex topics
- ✅ Still safe (+400 tokens total)

**Cons:**
- ❌ Slightly slower
- ❌ More token usage

**Example:**
```
Q1-Q7: All about Japan travel
Q8: "What about lodging?"
    → Remembers Q2-Q7, knows context is Japan ✅

Q9-Q10: Follow-ups
    → Still tracking Japan context ✅
```

---

### 10+ Exchanges (Risky):

**Pros:**
- ✅ Very long memory

**Cons:**
- ❌ Risk of hitting token limits
- ❌ Slower processing
- ❌ May fail on complex queries

**Not recommended unless you have specific needs.**

---

## 🎨 Visual Comparison

### 3 Exchanges:
```
[Remembered: Q3, Q4, Q5]
[Forgotten: Q1, Q2]
Current: Q6
```

### 5 Exchanges:
```
[Remembered: Q2, Q3, Q4, Q5, Q6]
[Forgotten: Q1]
Current: Q7
```

### 7 Exchanges:
```
[Remembered: Q1, Q2, Q3, Q4, Q5, Q6, Q7]
[Forgotten: none yet]
Current: Q8
```

---

## ⚠️ Trade-offs to Consider

### More Context = Better Memory
```
✅ AI remembers longer conversations
✅ Better for multi-step topics
✅ Fewer "New Conversation" resets needed
```

### More Context = More Tokens
```
⚠️ Each exchange ≈ 60-80 tokens
⚠️ 7 exchanges ≈ 500 tokens of context
⚠️ Leaves less room for long responses
```

### More Context = Slightly Slower
```
⚠️ Model processes more text
⚠️ ~0.1-0.3s slower per query
⚠️ Usually not noticeable
```

---

## 🎯 My Recommendations

### For Most Users: **5 Exchanges**
```
Perfect balance:
✅ Good memory (10 messages)
✅ Safe token usage
✅ Fast responses
✅ Handles multi-turn conversations
```

### For Complex Conversations: **7 Exchanges**
```
Extended memory:
✅ Great for travel planning
✅ Long currency discussions
✅ Multi-country comparisons
✅ Still safe on tokens
```

### For Quick Q&A: **Keep 3 Exchanges**
```
Current setting:
✅ Fastest
✅ Safest
✅ Good for simple conversions
```

---

## 📝 Implementation Guide

**I recommend increasing to 5 exchanges.** Here's how:

### Step 1: Update AIAssistantView.swift

```swift
// Around line 327 (comment update)
// Get last 14 messages (up to 7 exchanges) 
let recentMessages = assistant.conversationHistory.suffix(14)

// Around line 345
// Limit to last 5 exchanges (good balance)
if history.count >= 5 {
    break
}

// Around line 351
return Array(history.prefix(5))
```

### Step 2: Update CurrencyAIEngine.swift

```swift
// Around line 121
let recentHistory = conversationHistory.suffix(5)
```

### Step 3: Update Comment

```swift
// Around line 120
// Only include last 5 exchanges to maintain context without exceeding limits
```

---

## 🧪 How to Test

**After increasing to 5 exchanges:**

1. **Start a conversation**
2. **Ask 7-8 questions** on the same topic
3. **Check if AI remembers** context from earlier questions
4. **Monitor console** for any token errors

**Expected result:**
```
Q1: "What is Japan's currency?"
Q2: "How much is 100 USD?"
Q3: "What about 200?"
Q4: "And 300?"
Q5: "What about 400?"
Q6: "And 500?" 
    → Should still know we're talking about Japan/USD/JPY ✅
Q7: "Is that a good rate?"
    → Should still have context ✅
```

---

## 📊 Token Budget After Increase

### With 5 Exchanges:
```
System instructions:    400 tokens
Context (5 exchanges):  350 tokens (+150 from before)
Current query:           50 tokens
Reserved for response:  500 tokens
─────────────────────────────────
TOTAL:                 1300 tokens (~60% of limit)
```

**Still safe!** ✅

### With 7 Exchanges:
```
System instructions:    400 tokens
Context (7 exchanges):  500 tokens (+300 from before)
Current query:           50 tokens
Reserved for response:  500 tokens
─────────────────────────────────
TOTAL:                 1450 tokens (~70% of limit)
```

**Still safe!** ✅

---

## 🎊 Summary

**Can you increase context?** ✅ **YES!**

**Safe increases:**
- **5 exchanges:** Recommended for most users
- **7 exchanges:** Great for complex conversations
- **10 exchanges:** Maximum safe limit

**How to do it:**
- Change 3 to 5 (or 7) in two files
- 3 line changes total
- Immediate effect

**Benefits:**
- ✅ Better conversation memory
- ✅ Fewer "forgot context" issues
- ✅ Better multi-turn discussions
- ✅ Still safe on tokens

**Want me to implement this?** I can:
- Increase to 5 exchanges (recommended)
- Or 7 for extended memory
- Or make it configurable

Let me know! 📏

