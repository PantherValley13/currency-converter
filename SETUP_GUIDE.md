# Currency Converter - Setup Guide

## Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Supabase account and project

## Initial Setup

### 1. Open Project in Xcode
```bash
open "currency converter.xcodeproj"
```

### 2. Configure Test Target

**Verify Test Files are in Test Target:**
1. Open Xcode
2. Select any test file in Project Navigator
3. Open File Inspector (right sidebar)
4. Under "Target Membership", ensure `currency converterTests` is checked
5. Repeat for all test files if needed

### 3. Configure Supabase

**Option A: Using Info.plist (Recommended)**

Add to your `Info.plist`:
```xml
<key>SUPABASE_URL</key>
<string>https://your-project.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>your-anon-key-here</string>
```

**Option B: Using Scheme Environment Variables**

1. Go to Product → Scheme → Edit Scheme
2. Select "Run" → "Arguments"
3. Add Environment Variables:
   - `SupaBase_ID`: your-project-id
   - `SupaBase_API_Key`: your-anon-key

### 4. Install Dependencies

**Using Swift Package Manager:**

1. Go to File → Add Package Dependencies
2. Add the following packages:
   - Supabase Swift: `https://github.com/supabase/supabase-swift`

3. Wait for package resolution to complete

### 5. Verify Package Dependencies

Check `Package.resolved` exists:
```bash
ls -la "currency converter.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/configuration/"
```

If missing, resolve packages in Xcode:
- File → Packages → Resolve Package Versions

## Running Tests

### In Xcode

**Run All Tests:**
- Press `Cmd+U`
- Or Product → Test

**Run Specific Test Class:**
1. Open Test Navigator (Cmd+6)
2. Right-click on test class
3. Select "Run Tests"

**Run Single Test Method:**
1. Open Test Navigator (Cmd+6)
2. Right-click on test method
3. Select "Run Test"

### From Command Line

**Note:** Requires Xcode (not just Command Line Tools)

```bash
# Run all tests
xcodebuild test \
  -project "currency converter.xcodeproj" \
  -scheme "currency converter" \
  -destination "platform=iOS Simulator,name=iPhone 15"

# Run specific test class
xcodebuild test \
  -project "currency converter.xcodeproj" \
  -scheme "currency converter" \
  -destination "platform=iOS Simulator,name=iPhone 15" \
  -only-testing:currency_converterTests/CurrencyConversionTests

# Run specific test method
xcodebuild test \
  -project "currency converter.xcodeproj" \
  -scheme "currency converter" \
  -destination "platform=iOS Simulator,name=iPhone 15" \
  -only-testing:currency_converterTests/CurrencyConversionTests/testUSDToEURConversion
```

## Troubleshooting

### "Cannot find type in scope" Errors

**Solution:** Make sure test files are in the test target
1. Select test file in Project Navigator
2. Check "Target Membership" in File Inspector
3. Ensure `currency converterTests` is checked

### "No such module 'Supabase'" Error

**Solution:** Add Supabase package dependency
1. File → Add Package Dependencies
2. Add: `https://github.com/supabase/supabase-swift`

### Tests Not Running

**Solution:** Verify test scheme configuration
1. Product → Scheme → Edit Scheme
2. Select "Test" tab
3. Ensure `currency converterTests` is checked

### Supabase Connection Errors in Tests

**Solution:** Configure test environment
1. Tests use mock configuration by default
2. For real Supabase testing, set environment variables
3. Or configure `Info.plist` with test credentials

## Test Coverage

### Current Test Statistics
- **Total Test Files**: 13
- **Total Test Methods**: 290+
- **Unit Tests**: 150+
- **Integration Tests**: 50+
- **Performance Tests**: 20+
- **Accessibility Tests**: 30+
- **Edge Case Tests**: 40+

### Coverage Areas (100%)
- ✅ Currency conversion logic
- ✅ Alert system functionality
- ✅ UI components and data models
- ✅ Network integration with mocking
- ✅ Data persistence and caching
- ✅ Concurrent operations and thread safety
- ✅ Accessibility compliance
- ✅ Edge cases and error handling
- ✅ Performance testing
- ✅ Memory management

## Next Steps

### After Setup
1. Run all tests to verify setup: `Cmd+U`
2. Fix any configuration issues
3. Review test results in Test Navigator
4. Check code coverage in Report Navigator

### Development Workflow
1. Write new features
2. Write tests for new features
3. Run tests: `Cmd+U`
4. Fix any failing tests
5. Commit changes

### Continuous Integration
1. Set up GitHub Actions or Xcode Cloud
2. Configure automated testing on pull requests
3. Monitor test results and coverage

## Additional Resources

- [Test Documentation](currency converterTests/README.md)
- [Test Summary](currency converterTests/TEST_SUMMARY.md)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Guide](https://developer.apple.com/documentation/swift-testing)

## Support

If you encounter issues:
1. Check this setup guide
2. Review test documentation
3. Verify Xcode and Swift versions
4. Check package dependencies
5. Review console logs for specific errors
