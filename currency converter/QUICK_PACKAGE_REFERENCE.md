# 🎯 Quick Reference: Package Your LLM

## TL;DR

**Best approach:** Create a Swift Package

### 5-Minute Setup:

1. **Create package folder:**
   ```bash
   mkdir ~/Developer/CurrencyLLMKit
   cd ~/Developer/CurrencyLLMKit
   mkdir -p Sources/CurrencyLLMKit
   ```

2. **Copy these files to `Sources/CurrencyLLMKit/`:**
   - `CurrencyAIEngine.swift`
   - `CurrencyModels.swift`

3. **Add `public` to everything you want to use:**
   ```swift
   public class CurrencyAIEngine { ... }
   public struct CurrencyResponse { ... }
   public func answerQuery(...) { ... }
   ```

4. **Create `Package.swift` in root:**
   ```swift
   // swift-tools-version: 5.9
   import PackageDescription
   
   let package = Package(
       name: "CurrencyLLMKit",
       platforms: [.iOS(.v18), .macOS(.v15)],
       products: [
           .library(name: "CurrencyLLMKit", targets: ["CurrencyLLMKit"]),
       ],
       targets: [
           .target(name: "CurrencyLLMKit", dependencies: []),
       ]
   )
   ```

5. **Add to your app:**
   - Xcode → File → Add Package Dependencies
   - Click "Add Local..."
   - Select `~/Developer/CurrencyLLMKit`

6. **Use it:**
   ```swift
   import CurrencyLLMKit
   
   let response = await CurrencyAIEngine.shared.answerQuery("What is USD?")
   ```

---

## Files You Need

### Essential:
- ✅ `CurrencyAIEngine.swift` (your LLM engine)
- ✅ `CurrencyModels.swift` (your @Generable structs)
- ✅ `Package.swift` (package manifest)

### Optional:
- ✅ `README.md` (usage docs)
- ✅ Tests (for validation)

---

## What to Change

### In Your Files:

**Before:**
```swift
class CurrencyAIEngine { ... }
struct CurrencyResponse { ... }
```

**After:**
```swift
public class CurrencyAIEngine { ... }
public struct CurrencyResponse { ... }
```

**Add `public` to:**
- Classes: `public class`
- Structs: `public struct`
- Enums: `public enum`
- Functions: `public func`
- Properties: `public var` / `public let`
- Initializers: `public init(...)`

**Keep private:**
- Internal implementation details
- Helper methods
- Private variables

---

## Use in Multiple Apps

### App 1:
```swift
import CurrencyLLMKit
let llm = CurrencyAIEngine.shared
```

### App 2:
```swift
import CurrencyLLMKit
let llm = CurrencyAIEngine.shared
```

**Same code, same functionality!** ✅

---

## Two Approaches

### Option A: Currency-Specific Package
**Package:** `CurrencyLLMKit`
- Contains your currency-specific engine
- Contains your currency models
- Use in currency-related apps

### Option B: Generic + Specific (Recommended)
**Package 1:** `FoundationModelsKit` (generic LLM wrapper)
- Use in ANY app (weather, recipes, finance, etc.)

**Package 2:** `CurrencyLLMKit` (depends on FoundationModelsKit)
- Currency-specific stuff
- Use in currency apps

**Benefits:** Maximum reusability!

---

## Want Me To Create It?

I can:
1. ✅ Generate all the files
2. ✅ Set up the package structure
3. ✅ Make everything public
4. ✅ Create Package.swift
5. ✅ Write a README

**Just say:** "Create the package" and I'll do it!

Or specify:
- "Create generic LLM package" (for any use)
- "Create currency-specific package" (just for currency)
- "Create both packages" (generic + currency)

---

**See `LLM_PACKAGE_GUIDE.md` for full details!**

