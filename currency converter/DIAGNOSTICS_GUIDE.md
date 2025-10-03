# Console Logging Diagnostics Guide

## I've Added Aggressive Debug Logging

You should now see **detailed logs** as soon as the app starts. If you're seeing NOTHING, follow this guide.

---

## Step 1: Verify Console is Visible

### In Xcode:
1. **Show Debug Area:** Press `Shift + Cmd + Y`
2. **Bottom panel should appear** with two tabs
3. **Click "Console" tab** (right side)
4. You should see text output there

### What It Looks Like:
```
[Text output area at bottom of Xcode window]
```

---

## Step 2: Clean Build and Run

### Do a Complete Clean:
```
1. Stop the app (■ button or Cmd + .)
2. Press Shift + Cmd + K (Clean Build Folder)
3. Wait for "Clean Finished"
4. Press Cmd + R (Run)
```

---

## Step 3: What You SHOULD See

### Immediately When App Launches:
```
🎬 AIAssistantView: View appeared - starting initialization
🔍 Checking model availability...
📊 Model Available: false
📋 Status: Enable Apple Intelligence in Settings to use on-device AI
🚨 DEBUG: prewarmModel() called
✅ FoundationModels CAN be imported
📊 Model availability: unavailable(...)
⚠️  Cannot prewarm: Model not available
📋 Reason: Enable Apple Intelligence in Settings...
```

### When You Send a Message:
```
🚨 DEBUG: sendMessage() called!
📝 Input text: 'test'
✅ Sanitized query: 'test'
🔍 Processing Query...
🤖 Model Available: false
⚠️  Model Status: Enable Apple Intelligence in Settings...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 AIEngine: LLM Query Parsing (Structured Output)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Query: "test"
⚠️  Model Not Available - Cannot Parse
```

---

## Step 4: Troubleshooting

### Scenario A: NO LOGS AT ALL

**Possible Causes:**
1. Console not visible
2. App not actually running
3. Build failed silently

**Solution:**
```
1. Check for red errors in Xcode (top bar)
2. Look at the left panel - is there a build error?
3. Try: Product → Clean Build Folder
4. Try: Restart Xcode
5. Try: Delete app from device, rebuild
```

---

### Scenario B: Logs Show "Model Not Available"

**This is EXPECTED** if you don't have Apple Intelligence enabled.

**Console will show:**
```
📊 Model Available: false
📋 Status: Enable Apple Intelligence in Settings to use on-device AI
```

**What This Means:**
- ✅ Code is working correctly
- ❌ Apple Intelligence is not available on your device

**Requirements:**
- iPhone 15 Pro or later (NOT regular iPhone 15)
- iOS 18.1 or later
- Apple Intelligence enabled in Settings
- English (US) language

---

### Scenario C: Logs Show "FoundationModels CANNOT be imported"

**Console will show:**
```
❌ FoundationModels CANNOT be imported - check your build settings
```

**This means:**
- The framework isn't available
- Wrong deployment target
- Wrong SDK

**Solution:**
1. Check deployment target: iOS 18.1+
2. Check SDK: Latest Xcode
3. Check device: M1+ Mac or iPhone 15 Pro+

---

## Step 5: Expected Behavior

### If Apple Intelligence IS Available:
```
📊 Model Available: true
🔥 Pre-warming model...
✅ Model pre-warmed successfully

[When you send message:]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 AIEngine: LLM Query Parsing (Structured Output)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Query: "What is Japan's currency?"
📤 FULL PROMPT BEING SENT:
[... full prompt ...]
🚀 Sending structured parsing request...
✅ Parsed Successfully!
⏱️  Parse Time: 0.45s
📊 Parsed Data:
├─ Intent: Currency Information
└─ Message: "Japan's currency is the Japanese Yen (JPY)."
```

### If Apple Intelligence is NOT Available:
```
📊 Model Available: false
⚠️  Cannot prewarm: Model not available

[When you send message:]
❌ LLM parsing failed completely
🎯 Reason: On-device model not available
📋 Status: Enable Apple Intelligence in Settings...
```

**The error message in the UI:**
```
⚠️ AI features require Apple Intelligence

Enable Apple Intelligence in Settings to use on-device AI

Please check:
• iOS 18.1+ or macOS 15.1+
• Apple Intelligence enabled in Settings
• Compatible device (iPhone 15 Pro or later, M1+ Mac)
```

---

## What to Do Next

### Option 1: You See NO LOGS
➡️ **Console isn't showing** or **app isn't building**
- Open console: `Shift + Cmd + Y`
- Clean build: `Shift + Cmd + K`
- Rebuild: `Cmd + B`
- Check for red errors

### Option 2: You See "Model Not Available"
➡️ **This is expected!** The code is working.
- Apple Intelligence isn't available
- Either enable it or accept the error message
- The app correctly detects and explains this

### Option 3: You See Logs but Wrong Behavior
➡️ **Copy the console output and share it**
- I can see exactly what's happening
- I can identify the issue
- I can provide a targeted fix

---

## Quick Test Commands

### Test 1: View Appears
```
Expected: Logs appear immediately when you switch to AI Chat tab
Should see: 🎬 AIAssistantView: View appeared...
```

### Test 2: Send Message
```
Expected: Logs appear when you type and send
Should see: 🚨 DEBUG: sendMessage() called!
```

### Test 3: Model Check
```
Expected: Shows availability status
Should see: 📊 Model Available: true or false
```

---

## Summary

✅ **I've added extensive debug logging**  
✅ **Logs print at every step**  
✅ **You can now see exactly what's happening**  

**Do this now:**
1. Clean build (`Shift + Cmd + K`)
2. Run (`Cmd + R`)
3. Open console (`Shift + Cmd + Y`)
4. Switch to AI Chat tab
5. **Look at console** - you should see logs!
6. Send a test message
7. **Look at console** - you should see MORE logs!

**Then tell me:**
- Do you see ANY logs?
- If yes, copy/paste them here
- If no, what do you see in the console area?

This will tell us exactly what's going on! 🔍

