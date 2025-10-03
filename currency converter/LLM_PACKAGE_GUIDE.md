# 📦 Creating a Reusable LLM Package

## Overview

You can package your currency LLM functionality as a **Swift Package** that can be:
- ✅ Used in multiple apps
- ✅ Version controlled separately
- ✅ Easily updated across projects
- ✅ Shared with other developers (optional)

---

## Option 1: Swift Package Manager (Recommended)

### Step 1: Create Package Structure

Create a new directory for your package:

```
CurrencyLLMKit/
├── Package.swift
├── Sources/
│   └── CurrencyLLMKit/
│       ├── CurrencyAIEngine.swift
│       ├── CurrencyModels.swift
│       └── CurrencyLLMKit.swift (public interface)
└── README.md
```

### Step 2: Create Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CurrencyLLMKit",
    platforms: [
        .iOS(.v18),  // Foundation Models requires iOS 18+
        .macOS(.v15) // Foundation Models requires macOS 15+
    ],
    products: [
        .library(
            name: "CurrencyLLMKit",
            targets: ["CurrencyLLMKit"]
        ),
    ],
    dependencies: [
        // No external dependencies - uses system FoundationModels
    ],
    targets: [
        .target(
            name: "CurrencyLLMKit",
            dependencies: [],
            path: "Sources/CurrencyLLMKit"
        ),
    ]
)
```

### Step 3: Create Public Interface

**Sources/CurrencyLLMKit/CurrencyLLMKit.swift:**

```swift
import Foundation
import FoundationModels

/// Public interface for CurrencyLLMKit
/// Use CurrencyLLMEngine to interact with the on-device LLM
public enum CurrencyLLMKit {
    /// The shared engine instance
    public static let engine = CurrencyLLMEngine.shared
    
    /// Check if AI is available on this device
    public static var isAvailable: Bool {
        engine.isAvailable
    }
    
    /// Get availability description for debugging
    public static var availabilityDescription: String {
        engine.availabilityDescription
    }
    
    /// Pre-warm the model for faster first response
    public static func prewarm() {
        engine.prewarm()
    }
    
    /// Reset the LLM session (useful after errors or context clearing)
    public static func resetSession() {
        engine.resetSession()
    }
}
```

### Step 4: Make Your Models Public

**Sources/CurrencyLLMKit/CurrencyModels.swift:**

```swift
import Foundation
import FoundationModels

// Make all types public
@Generable
public struct CurrencyResponse {
    public let queryType: QueryType
    public let title: String
    public let answer: String
    public let conversionDetails: ConversionDetails?
    public let travelAdvice: TravelAdvice?
    public let currencyInfo: CurrencyInfo?
    
    public init(queryType: QueryType, title: String, answer: String, 
                conversionDetails: ConversionDetails? = nil,
                travelAdvice: TravelAdvice? = nil,
                currencyInfo: CurrencyInfo? = nil) {
        self.queryType = queryType
        self.title = title
        self.answer = answer
        self.conversionDetails = conversionDetails
        self.travelAdvice = travelAdvice
        self.currencyInfo = currencyInfo
    }
}

@Generable
public enum QueryType: String {
    case conversion
    case travelAdvice
    case currencyInfo
    case rateInquiry
    case general
}

// ... rest of your models, all marked as `public`
```

### Step 5: Make Your Engine Public

**Sources/CurrencyLLMKit/CurrencyAIEngine.swift:**

```swift
import Foundation
import FoundationModels

public final class CurrencyLLMEngine {
    public static let shared = CurrencyLLMEngine()
    
    private init() {
        print("🔧 CurrencyLLMEngine: Initializing")
    }
    
    // Make all public methods and properties `public`
    public var isAvailable: Bool { ... }
    public var availabilityDescription: String { ... }
    public func prewarm() { ... }
    public func resetSession() { ... }
    public func answerQuery(...) async -> CurrencyResponse? { ... }
    
    // Keep private implementation details private
    private var session: LanguageModelSession!
    private func createSession() -> LanguageModelSession { ... }
}
```

### Step 6: Use in Your App

**In your app's Xcode project:**

1. **Add Local Package:**
   - File → Add Package Dependencies
   - Click "Add Local..."
   - Select your `CurrencyLLMKit` folder

2. **Or add via path in Package.swift (if your app uses SPM):**
   ```swift
   dependencies: [
       .package(path: "../CurrencyLLMKit")
   ]
   ```

3. **Import and use:**
   ```swift
   import CurrencyLLMKit
   
   // Check availability
   if CurrencyLLMKit.isAvailable {
       CurrencyLLMKit.prewarm()
   }
   
   // Use the engine
   Task {
       let response = await CurrencyLLMKit.engine.answerQuery("What is the currency of Japan?")
       print(response?.answer ?? "No response")
   }
   ```

---

## Option 2: Framework Target (Less Flexible)

### Create a Framework in Xcode

1. **Add New Target:**
   - File → New → Target
   - Choose "Framework"
   - Name it "CurrencyLLMKit"

2. **Add Your Files:**
   - Drag `CurrencyAIEngine.swift`, `CurrencyModels.swift` to the framework
   - Mark them as part of the framework target

3. **Make Types Public:**
   - Add `public` to all classes, structs, enums you want to expose

4. **Link FoundationModels:**
   - In framework's Build Phases
   - Link Binary With Libraries → Add FoundationModels

5. **Use in Other Apps:**
   - Drag the built framework to other projects
   - Or use Carthage/CocoaPods to distribute

**Cons:**
- ❌ More complex than SPM
- ❌ Binary compatibility issues
- ❌ Harder to maintain across Xcode versions
- ❌ Not recommended for modern Swift development

---

## Option 3: Git Submodule (For Multiple Projects)

### Setup

1. **Create a separate Git repo for your package:**
   ```bash
   mkdir CurrencyLLMKit
   cd CurrencyLLMKit
   git init
   # Create Package.swift and Sources/ as shown above
   git add .
   git commit -m "Initial commit"
   git remote add origin <your-git-url>
   git push -u origin main
   ```

2. **Add as submodule in your apps:**
   ```bash
   cd YourApp
   git submodule add <your-git-url> Packages/CurrencyLLMKit
   ```

3. **In Xcode:**
   - File → Add Package Dependencies
   - Add Local → Select `Packages/CurrencyLLMKit`

**Benefits:**
- ✅ Version control separate from app
- ✅ Can update across multiple projects
- ✅ Share between team members

---

## Option 4: Generic LLM Wrapper (Most Reusable)

### Create a Generic Foundation Models Wrapper

If you want something even more reusable (not just currency), create a generic wrapper:

**GenericLLMKit Package Structure:**

```
GenericLLMKit/
├── Package.swift
└── Sources/
    └── GenericLLMKit/
        ├── LLMEngine.swift (generic engine)
        ├── LLMSession.swift (session management)
        └── LLMError.swift (error types)
```

**LLMEngine.swift:**

```swift
import Foundation
import FoundationModels

/// Generic LLM engine that can be configured for any use case
public final class LLMEngine {
    private let instructions: Instructions
    private var session: LanguageModelSession!
    private let model = SystemLanguageModel.default
    
    public init(instructions: String) {
        self.instructions = Instructions { instructions }
        createSession()
    }
    
    public var isAvailable: Bool {
        model.availability == .available
    }
    
    public func resetSession() {
        createSession()
    }
    
    private func createSession() {
        session = LanguageModelSession(instructions: instructions)
    }
    
    /// Ask a question and get a response
    public func ask(_ query: String) async throws -> String {
        guard isAvailable else {
            throw LLMError.unavailable
        }
        
        let prompt = Prompt { query }
        let response = try await session.respond(to: prompt)
        return response.content
    }
    
    /// Ask with structured output
    public func ask<T: Generable>(_ query: String, generating type: T.Type) async throws -> T {
        guard isAvailable else {
            throw LLMError.unavailable
        }
        
        let prompt = Prompt { query }
        let response = try await session.respond(
            to: prompt,
            generating: type,
            options: GenerationOptions(sampling: .greedy)
        )
        return response.content
    }
}

public enum LLMError: Error {
    case unavailable
    case sessionError
}
```

**Then in your currency app:**

```swift
import GenericLLMKit

class CurrencyLLMHelper {
    private let engine = LLMEngine(instructions: """
        You are a currency expert...
        [your currency-specific instructions]
    """)
    
    func askCurrencyQuestion(_ query: String) async throws -> CurrencyResponse {
        return try await engine.ask(query, generating: CurrencyResponse.self)
    }
}
```

**Benefits:**
- ✅ Super reusable across ANY domain
- ✅ Can use for currency, weather, cooking, etc.
- ✅ One package, many use cases

---

## Recommended Approach

### For Your Use Case:

**I recommend Option 1 (Swift Package) with a twist:**

Create **TWO** packages:

1. **`FoundationModelsKit`** (Generic, super reusable)
   - Generic LLM engine
   - Session management
   - Error handling
   - Can use in ANY app

2. **`CurrencyLLMKit`** (Domain-specific)
   - Depends on `FoundationModelsKit`
   - Currency-specific models
   - Currency-specific instructions
   - Use in currency apps

### Why?

- ✅ `FoundationModelsKit` is useful for ALL your future LLM apps
- ✅ `CurrencyLLMKit` is your domain knowledge
- ✅ Other apps can use `FoundationModelsKit` with their own models
- ✅ DRY (Don't Repeat Yourself)

---

## File Checklist for Package

### Essential Files:

- ✅ `CurrencyAIEngine.swift` (rename to `CurrencyLLMEngine.swift`)
- ✅ `CurrencyModels.swift` (all your @Generable structs)
- ✅ `Package.swift` (package manifest)
- ✅ `README.md` (usage documentation)

### Make Public:

For each type/function you want to use from other apps:

```swift
// ❌ Before (internal by default)
class CurrencyAIEngine { ... }

// ✅ After (public for package use)
public class CurrencyLLMEngine { ... }
```

**Rule:** If another app needs it, mark it `public`. Otherwise, keep it `private` or `internal`.

---

## Quick Start Template

### Minimal Working Package

**Package.swift:**
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

**Sources/CurrencyLLMKit/CurrencyLLMKit.swift:**
```swift
import Foundation
import FoundationModels

public class CurrencyLLM {
    public static let shared = CurrencyLLM()
    private init() {}
    
    // Your implementation
}
```

**That's it!** Now you can use it:

```swift
import CurrencyLLMKit

let response = await CurrencyLLM.shared.answerQuery("What is USD?")
```

---

## Usage in Multiple Apps

### App 1: Currency Converter
```swift
import CurrencyLLMKit

let llm = CurrencyLLMKit.engine
let response = await llm.answerQuery("Convert 100 USD to EUR")
```

### App 2: Travel Budget App
```swift
import CurrencyLLMKit

let llm = CurrencyLLMKit.engine
let response = await llm.answerQuery("Budget for Japan trip")
```

### App 3: Finance Tracker
```swift
import CurrencyLLMKit

let llm = CurrencyLLMKit.engine
let response = await llm.answerQuery("Compare USD vs EUR trends")
```

**Same package, different apps!** ✅

---

## Advanced: Configurable Package

### Make it Customizable

```swift
public struct CurrencyLLMConfig {
    public let systemInstructions: String
    public let maxQueryLength: Int
    public let contextSize: Int
    
    public static let `default` = CurrencyLLMConfig(
        systemInstructions: "You are a currency expert...",
        maxQueryLength: 300,
        contextSize: 7
    )
    
    public init(systemInstructions: String, maxQueryLength: Int, contextSize: Int) {
        self.systemInstructions = systemInstructions
        self.maxQueryLength = maxQueryLength
        self.contextSize = contextSize
    }
}

public class CurrencyLLM {
    private let config: CurrencyLLMConfig
    
    public init(config: CurrencyLLMConfig = .default) {
        self.config = config
    }
}
```

**Use custom config:**
```swift
let customConfig = CurrencyLLMConfig(
    systemInstructions: "Be extra helpful with Euro conversions...",
    maxQueryLength: 500,
    contextSize: 10
)
let llm = CurrencyLLM(config: customConfig)
```

---

## Testing Your Package

### In the Package Itself

Add tests:

```
CurrencyLLMKit/
├── Package.swift
├── Sources/
│   └── CurrencyLLMKit/
└── Tests/
    └── CurrencyLLMKitTests/
        └── CurrencyLLMTests.swift
```

**CurrencyLLMTests.swift:**
```swift
import XCTest
@testable import CurrencyLLMKit

final class CurrencyLLMTests: XCTestCase {
    func testAvailability() {
        let engine = CurrencyLLMKit.engine
        XCTAssertNotNil(engine)
    }
    
    func testQueryProcessing() async throws {
        let engine = CurrencyLLMKit.engine
        guard engine.isAvailable else {
            throw XCTSkip("AI not available on this device")
        }
        
        let response = await engine.answerQuery("What is USD?")
        XCTAssertNotNil(response)
    }
}
```

---

## Distribution Options

### 1. Local Only (Recommended for Personal Use)
- Keep package in `~/Developer/Packages/CurrencyLLMKit`
- Add as local package in each app

### 2. Git Repository (For Team/Multiple Devices)
- Push to GitHub/GitLab
- Add via URL in Xcode

### 3. Private Package Registry (Enterprise)
- Use GitHub Packages
- Or private package server

### 4. Public (Open Source)
- Push to GitHub public
- Others can use it too!

---

## Summary

### Best Approach for You:

1. **Create Swift Package** ✅
   - Modern, clean, Apple-recommended
   - Easy to maintain
   - Works with Xcode and SPM

2. **Include These Files:**
   - `CurrencyAIEngine.swift` (make public)
   - `CurrencyModels.swift` (make public)
   - `Package.swift` (manifest)

3. **Mark Everything Public:**
   - `public class CurrencyLLMEngine`
   - `public struct CurrencyResponse`
   - `public func answerQuery(...)`

4. **Use in Any App:**
   - Add as local package
   - Import and use
   - Same functionality everywhere!

---

## Next Steps

1. **Want me to create the package structure for you?**
   - I can generate all the files
   - Set up the Package.swift
   - Make everything public
   - Create a README

2. **Or want a more generic wrapper?**
   - Create `FoundationModelsKit` for any LLM use
   - Then `CurrencyLLMKit` for currency-specific
   - Maximum reusability

**Let me know which approach you prefer and I'll create it for you!** 🚀

