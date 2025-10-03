# Conversational Flow Guide

## How the LLM Now Handles Different Conversation Patterns

This guide shows how the improved system handles various conversation patterns.

---

## Pattern 1: Simple Query → Answer

```
User: "What is Japan's currency?"
```

**System Flow:**
1. ✅ No context patterns detected → Treat as new query
2. ✅ Parse with LLM → Intent: CurrencyInfo, Complete: true
3. ✅ Response: "Japan's currency is the Japanese Yen (JPY)."

**Logs:**
```
💭 No reference pattern - treating as new query
📊 LLM Parse Result:
├─ Intent: Currency Information
├─ Complete: true
└─ Amount: nil
💬 Response: "Japan's currency is the Japanese Yen (JPY)."
```

---

## Pattern 2: Query → Follow-up with Context

```
User: "What is Mexico's currency?"
AI: "Mexico's currency is the Mexican Peso (MXN)."

User: "How much peso would 1000 dollars be?"
```

**System Flow:**
1. ✅ Context detected: "Recent currency: MXN"
2. ✅ Pronoun "peso" references context
3. ✅ Parse: amount=1000, from=USD, to=MXN
4. ✅ Response + Conversion Action

**Logs:**
```
💭 Context Found (reference detected): Recent currency: MXN
📊 LLM Parse Result:
├─ Intent: Conversion
├─ Complete: true
├─ From: USD
├─ To: MXN
└─ Amount: 1000.0
🔔 Triggering Conversion Action
```

---

## Pattern 3: Implicit Continuation

```
User: "100 USD to EUR"
AI: "100 USD is approximately 92 EUR."

User: "What about GBP?"
```

**System Flow:**
1. ✅ "What about" → Implicit continuation detected
2. ✅ Context: "Recent mention: 100 USD, EUR"
3. ✅ Parse: amount=100, from=USD, to=GBP
4. ✅ Response + Conversion

**Logs:**
```
💭 Context Found (reference detected): Recent mention: 100 USD
📊 LLM Parse Result:
├─ Intent: Conversion
├─ Complete: true
├─ From: USD
├─ To: GBP
└─ Amount: 100.0
```

---

## Pattern 4: Context Reset (NEW!)

```
User: "What is Mexico's currency?"
AI: "Mexico's currency is the Mexican Peso (MXN)."

User: "By the way, what is Argentina's currency?"
```

**System Flow:**
1. ✅ "By the way" → Context reset signal detected
2. ✅ Context is NOT applied
3. ✅ Parse: Intent=CurrencyInfo, Complete=true
4. ✅ Response: "Argentina's currency is the Argentine Peso (ARS)."

**Key Point:** The system correctly answers about Argentina, NOT Mexico!

**Logs:**
```
💭 Context reset detected - treating as fresh query
📊 LLM Parse Result:
├─ Intent: Currency Information
├─ Complete: true
💬 Response: "Argentina's currency is the Argentine Peso (ARS)."
```

---

## Pattern 5: Rich Context with Amounts

```
User: "1000 to 1500 USD"
AI: "That's a range of $1,000 to $1,500 USD."

User: "How much peso would that be?"
```

**System Flow:**
1. ✅ "that" → Pronoun detected
2. ✅ Rich context extracted: "Recent mention: 1000 to 1500 USD"
3. ✅ LLM sees both amounts AND currencies
4. ✅ Converts both: 1000 USD → 19,000 MXN, 1500 USD → 28,500 MXN

**Logs:**
```
💭 Context Found (reference detected): Recent mention: 1000 to 1500 USD
📊 LLM Parse Result:
├─ Intent: Conversion
├─ From: USD
├─ To: MXN
└─ Amount: 1000.0
💬 Response: "1000 USD is approximately 19,000 MXN. For 1500 USD, about 28,500 MXN."
```

---

## Pattern 6: Ambiguous Query

```
User: "How much is 100?"
```

**System Flow:**
1. ✅ No context available
2. ✅ Parse: Intent=Conversion, Complete=FALSE
3. ✅ Response asks for clarification with examples

**Logs:**
```
💭 No reference pattern - treating as new query
📊 LLM Parse Result:
├─ Intent: Conversion
├─ Complete: false
├─ From: nil
├─ To: nil
└─ Amount: 100.0
💬 Response: "Could you specify which currencies? For example: '100 USD to EUR' or '100 Mexican Pesos to Dollars'"
```

---

## Pattern 7: Explicit Override of Context

```
User: "What is Mexico's currency?"
AI: "Mexico's currency is the Mexican Peso (MXN)."

User: "What is Argentina's currency?"
```

**System Flow:**
1. ✅ No reference pattern ("that", "it", etc.) detected
2. ✅ Context is NOT applied
3. ✅ "Argentina" explicitly mentioned → Answer about Argentina!

**Key Point:** Even though MXN was just discussed, the system correctly answers about Argentina.

**Logs:**
```
💭 No reference pattern - treating as new query
📊 LLM Parse Result:
├─ Intent: Currency Information
💬 Response: "Argentina's currency is the Argentine Peso (ARS)."
```

**System Instructions Help Here:**
```
• If query mentions specific currency/country → Answer about THAT (ignore any context)
Example: "What is Argentina's currency" [context: MXN] → Answer: ARS [NOT MXN!]
```

---

## Pattern 8: Multi-Step with Mixed Intents

```
User: "What is Japan's currency?"
AI: "Japan's currency is the Japanese Yen (JPY)."

User: "How much is 100 of that to USD?"
AI: "100 JPY is approximately 0.68 USD."

User: "What about EUR?"
AI: "100 JPY is approximately 0.62 EUR."

User: "Actually, what is China's currency?"
AI: "China's currency is the Chinese Yuan (CNY)."
```

**System Flow Analysis:**

**Query 1:** New topic (CurrencyInfo)
- No context → Answer about Japan

**Query 2:** Reference with pronoun ("that")
- Context applied → JPY from previous message
- Conversion: 100 JPY → USD

**Query 3:** Implicit continuation ("What about")
- Context applied → 100 JPY from previous
- Conversion: 100 JPY → EUR

**Query 4:** New topic (no reference pattern)
- Context reset → Answer about China (NOT Japan!)

---

## Context Detection Summary

### ✅ Apply Context When:
- **Pronouns:** "that", "it", "this", "same", "those", "these"
- **Implicit continuations:** "what about", "how about", "and", "also", "too?", "as well"

### ❌ Ignore Context When:
- **Reset signals:** "anyway", "by the way", "btw", "new question"
- **Explicit mentions:** New country/currency name in query
- **No patterns:** Query is self-contained

### 🎯 Rich Context Includes:
- Currency codes (USD, EUR, MXN, etc.)
- Amounts ($1,000 or 1500 USD)
- Recent AI messages (last 6)

---

## Error Handling Patterns

### Pattern 9: Too Short Query
```
User: "a"
```
**System:** Ignores silently (< 2 characters)

### Pattern 10: Too Long Query
```
User: [500+ character message]
```
**System:** "Your message is too long. Please keep it under 500 characters."

### Pattern 11: LLM Parsing Fails
```
User: "jkldsjfkljsdf"
```
**System:** "I'm having trouble understanding that. Could you try asking differently? For example:
• 'What is Japan's currency?'
• '100 USD to EUR'
• 'How much is 50 dollars in pesos?'"

---

## Key Improvements

### 🎯 **Context Awareness**
- Knows when to use context vs. when to ignore it
- Prevents "context bleeding" into unrelated queries

### 🎯 **Intent Recognition**
- Distinguishes Conversion vs. CurrencyInfo vs. other intents
- Handles each appropriately

### 🎯 **Action-Oriented**
- Gives actual conversions, not explanations
- Direct answers for currency info questions

### 🎯 **Robust Error Handling**
- Sanitizes input
- Validates length
- Graceful fallbacks for parsing failures

### 🎯 **Rich Logging**
- Every step is traceable
- Easy debugging of conversation flow

---

## Testing Your Changes

### Recommended Test Sequence

1. **Basic Info Query:**
   ```
   "What is Japan's currency?"
   → Should answer: "Japan's currency is the Japanese Yen (JPY)."
   ```

2. **Contextual Follow-up:**
   ```
   "How much is 100 of that to USD?"
   → Should convert 100 JPY to USD using context
   ```

3. **Context Reset:**
   ```
   "By the way, what is Mexico's currency?"
   → Should answer about Mexico (NOT Japan!)
   ```

4. **Implicit Continuation:**
   ```
   "100 USD to EUR"
   "What about GBP?"
   → Should convert 100 USD to GBP
   ```

5. **Ambiguous Query:**
   ```
   "How much is 50?"
   → Should ask for clarification
   ```

6. **Edge Case:**
   ```
   "What is Puerto Rico's currency?"
   → Should answer: "Puerto Rico uses the US Dollar (USD)."
   ```

---

## Conclusion

The conversation system now handles:
✅ Multi-turn conversations  
✅ Context-dependent queries  
✅ Context resets  
✅ Implicit continuations  
✅ Ambiguity resolution  
✅ Edge cases  
✅ All intent types  

The LLM is **always used** (no hardcoded answers), but **guided effectively** through comprehensive system instructions and smart context management!

