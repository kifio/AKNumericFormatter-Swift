import Testing
import XCTest
@testable import AKNumericFormatter_Swift

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}


@Test func isFormatFulfilled() async throws {
    let formatter = AKNumericFormatter.formatter(with: "**:**:**", placeholder: Character("*"))
    #expect(!formatter.isFormatFulfilled("12:"))
    #expect(!formatter.isFormatFulfilled("12:34:*6"))
    #expect(!formatter.isFormatFulfilled("12:34x56"))
    #expect(formatter.isFormatFulfilled("12:34:56"))
    #expect(!formatter.isFormatFulfilled("12:34:56:"))
}

@Test
func unfixedDigits() async throws {
    let formatter = AKNumericFormatter.formatter(with: "+1(xxx)xx-77-xx", placeholder: Character("x"))
    #expect(throws: Never.self) { try formatter.unfixedDigits(string: "+1(234)56-77-89") == "2345689" }
}
