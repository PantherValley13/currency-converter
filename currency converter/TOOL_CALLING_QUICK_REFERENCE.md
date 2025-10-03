# 🎯 Tool Calling - Quick Reference

## What It Does

Your LLM now **automatically decides** when to use tools vs estimates.

---

## When Tools Are Used

### ✅ Tool Called For:
- "**Exact**" / "**Precise**" / "**Current**" rate requests
- "**Should I exchange now?**" type questions
- **Obscure currencies** not in reference list
- **Large amounts** ($1,000+)

### ❌ Estimate Used For:
- "**About**" / "**Approximately**" / "**Roughly**"
- **General** currency questions
- **Cultural** advice (tipping, etc.)
- **Quick** ballpark figures

---

## Examples

| Query | Mode | Time | Why |
|-------|------|------|-----|
| "About how much is 100 USD in EUR?" | Estimate | 2s | "About" = casual |
| "What's the EXACT rate for USD to EUR?" | Tool | 4s | "EXACT" = precision |
| "Can I tip in Japan?" | Estimate | 2s | Cultural info |
| "Convert USD to Bhutanese Ngultrum" | Tool | 4s | Obscure currency |
| "Should I exchange $5,000 now?" | Tool | 4s | Important decision |

---

## Console Logs

### When Tool Used:
```
🔧 Tool called: getCurrentExchangeRate(USD → EUR)
✅ Tool returned: 0.9187
```

### When Estimate Used:
```
(No tool log - direct answer)
```

---

## Test It

**Try these:**

1. "About how much is 100 USD in EUR?" → Fast estimate
2. "What's the EXACT rate?" → Tool called
3. "Can I tip in Japan?" → No tool
4. Turn off WiFi, ask for exact rate → Fallback to estimate

---

## Benefits

✅ **Fast** for casual questions (2s)  
✅ **Accurate** when needed (4s)  
✅ **Works offline** (fallback)  
✅ **All currencies** (not just top 60)  
✅ **Smart** (LLM decides automatically)

---

**See `TOOL_CALLING_IMPLEMENTED.md` for full details!**

