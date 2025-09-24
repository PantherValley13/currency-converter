import Foundation
#if canImport(Testing)
import Testing

@Suite("Supabase model and utility tests")
struct SupabaseModelsTests {

    @Test("AnyCodable round-trips primitives")
    func anyCodablePrimitives() throws {
        let values: [Any] = [
            "hello",
            42,
            3.14159,
            true
        ]
        for v in values {
            let wrapped = AnyCodable(v)
            let data = try JSONEncoder().encode(wrapped)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
            switch v {
            case let s as String:
                #expect((decoded.value as? String) == s)
            case let i as Int:
                #expect((decoded.value as? Int) == i)
            case let d as Double:
                // Allow small floating tolerance
                if let out = decoded.value as? Double {
                    #expect(abs(out - d) < 0.000_001)
                } else {
                    Issue.record("Decoded value is not Double")
                }
            case let b as Bool:
                #expect((decoded.value as? Bool) == b)
            default:
                Issue.record("Unhandled type in test: \(type(of: v))")
            }
        }
    }

    @Test("AnyCodable round-trips arrays and dictionaries")
    func anyCodableCollections() throws {
        let array: [Any] = ["a", 1, false]
        let dict: [String: Any] = [
            "name": "alex",
            "age": 30,
            "admin": true,
            "tags": ["one", "two"]
        ]

        // Array
        do {
            let wrapped = AnyCodable(array)
            let data = try JSONEncoder().encode(wrapped)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
            let out = decoded.value as? [Any]
            #expect(out != nil)
            #expect((out?.count ?? 0) == 3)
        }

        // Dictionary
        do {
            let wrapped = AnyCodable(dict)
            let data = try JSONEncoder().encode(wrapped)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
            let out = decoded.value as? [String: Any]
            #expect(out != nil)
            #expect((out?["name"] as? String) == "alex")
            #expect((out?["age"] as? Int) == 30)
            #expect((out?["admin"] as? Bool) == true)
        }
    }

    @Test("SupabaseProviderProfile CodingKeys and round-trip")
    func providerProfileCoding() throws {
        let profile = SupabaseProviderProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            key: "interbank",
            name: "Interbank",
            spreadPercent: Decimal(string: "0.5")!,
            fixedFee: Decimal(string: "2.00")!,
            isActive: true,
            createdAt: Date(timeIntervalSince1970: 0)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)

        // Ensure snake_case keys exist in JSON
        if let json = String(data: data, encoding: .utf8) {
            #expect(json.contains("\"spread_percent\""))
            #expect(json.contains("\"fixed_fee\""))
            #expect(json.contains("\"created_at\""))
        } else {
            Issue.record("Failed to stringify JSON")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SupabaseProviderProfile.self, from: data)
        #expect(decoded.key == profile.key)
        #expect(decoded.name == profile.name)
        #expect(decoded.isActive == profile.isActive)
        #expect(decoded.spreadPercent == profile.spreadPercent)
        #expect(decoded.fixedFee == profile.fixedFee)
    }

    @Test("CurrencyRate CodingKeys and round-trip")
    func currencyRateCoding() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let later = now.addingTimeInterval(3600)
        let rate = CurrencyRate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            baseCurrency: "USD",
            targetCurrency: "EUR",
            rate: Decimal(string: "0.92")!,
            provider: "interbank",
            createdAt: now,
            expiresAt: later
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(rate)

        if let json = String(data: data, encoding: .utf8) {
            #expect(json.contains("\"base_currency\""))
            #expect(json.contains("\"target_currency\""))
            #expect(json.contains("\"created_at\""))
            #expect(json.contains("\"expires_at\""))
        } else {
            Issue.record("Failed to stringify JSON")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CurrencyRate.self, from: data)
        #expect(decoded.baseCurrency == rate.baseCurrency)
        #expect(decoded.targetCurrency == rate.targetCurrency)
        #expect(decoded.provider == rate.provider)
        #expect(decoded.rate == rate.rate)
        #expect(abs(decoded.createdAt.timeIntervalSince1970 - now.timeIntervalSince1970) < 0.5)
        #expect(abs(decoded.expiresAt.timeIntervalSince1970 - later.timeIntervalSince1970) < 0.5)
    }

    @Test("Decimal to Double via NSDecimalNumber conversion")
    func decimalToDoubleConversion() {
        let d = Decimal(string: "1.2345")!
        let dbl = NSDecimalNumber(decimal: d).doubleValue
        #expect(abs(dbl - 1.2345) < 0.000_001)
    }
}
#endif
