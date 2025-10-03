# Xcode Cache Issue Fix

## Problem
Xcode is reporting: `Cannot find 'extractCurrencies' in scope` at line 292 in AIAssistantManager.swift

However, `extractCurrencies` no longer exists in the code - it was removed when we moved to 100% LLM-driven parsing.

## Cause
Xcode sometimes caches old compilation states and doesn't pick up file changes immediately.

## Solution: Clean Derived Data

### Option 1: In Xcode Menu
1. Go to **Xcode** → **Settings** (or **Preferences** on older versions)
2. Select the **Locations** tab
3. Click the **arrow** next to "Derived Data" path
4. In Finder, delete the folder for your project
5. Go back to Xcode and do **Product** → **Clean Build Folder** (Shift + Cmd + K)
6. Build again (Cmd + B)

### Option 2: Keyboard Shortcut
1. Press **Shift + Command + K** (Clean Build Folder)
2. Close and reopen the project
3. Build again (Cmd + B)

### Option 3: Quick Menu Clean
1. Hold **Option key**
2. Click **Product** menu
3. Select **Clean Build Folder** (appears when holding Option)
4. Build again

### Option 4: Full Reset (Nuclear Option)
1. Close Xcode completely
2. In Finder, go to: `~/Library/Developer/Xcode/DerivedData/`
3. Delete the entire DerivedData folder
4. Open Xcode and rebuild

## Verification

After cleaning, the error should disappear because:

✅ `extractCurrencies()` was removed from AIAssistantManager.swift  
✅ All parsing now uses `AIEngine.shared.parseQuery()`  
✅ No hardcoded regex or pattern matching remains

## What Was Replaced

**OLD (removed):**
```swift
private func extractCurrencies(from text: String) -> [String] {
    // 80+ lines of regex patterns
}

private func extractAmount(from text: String) -> Double? {
    // Regex for number extraction
}

private func inferTargetCurrency(from text: String) -> String {
    // Pattern matching
}
```

**NEW (current):**
```swift
// Use LLM to parse the query with structured output
guard let parsed = await AIEngine.shared.parseQuery(query, context: context) else {
    return nil
}

// LLM returns structured data:
// - amount, fromCurrency, toCurrency
// - intent, isComplete, responseMessage
```

## If Problem Persists

1. **Restart Xcode**
2. **Restart Mac** (forces all caches to clear)
3. **Check file is saved**: Look for dot (•) in file tab - if present, save with Cmd+S
4. **Check git status**: Make sure you're on the right branch

## Expected Behavior After Fix

✅ Project compiles without errors  
✅ All LLM features work as expected  
✅ No references to old parsing functions

