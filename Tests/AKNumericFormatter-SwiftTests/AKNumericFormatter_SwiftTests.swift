import Testing
import XCTest
@testable import AKNumericFormatter_Swift

@Test func testFormatString_noDigitPlaceholders() {
        let formatter = AKNumericFormatter.formatter(
            mask: "**:**:**",
            placeholder: Character("*")
        )
        
        #expect(formatter.format("1") == "1")
        #expect(formatter.format("12") == "12:")
        #expect(formatter.format("123") == "12:3")
        #expect(formatter.format("1*2*x3*4") == "12:34:")
        #expect(formatter.format("x*12345x*") == "12:34:5")
        #expect(formatter.format("1234567") == "12:34:56")
    }
    
    // MARK: - With Digit Placeholders
    @Test func testFormatString_withDigitPlaceholders_fillInMode() {
        let formatter = AKNumericFormatter.formatter(
            mask: "+1(xxx)xx-77-xx",
            placeholder: Character("x"),
            mode: .fillIn
        )
        
        #expect(formatter.format("1") == "+1(1")
        #expect(formatter.format("2") == "+1(2")
        #expect(formatter.format("123") == "+1(123)")
        #expect(formatter.format("1*2*x3*4") == "+1(123)4")
        #expect(formatter.format("x*12345x*") == "+1(123)45-77-")
        #expect(formatter.format("1234567") == "+1(123)45-77-67")
        #expect(formatter.format("12345678") == "+1(123)45-77-67")
    }
    
    @Test func testFormatString_withDigitPlaceholders_strictMode() {
        let formatter = AKNumericFormatter.formatter(
            mask: "+1(xxx)xx-77-xx",
            placeholder: Character("x"),
            mode: .strict
        )
        
        #expect(formatter.format("1") == "+1(")
        #expect(formatter.format("2") == "")
        #expect(formatter.format("123") == "+1(23")
        #expect(formatter.format("1234") == "+1(234)")
        #expect(formatter.format("123456") == "+1(234)56-")
        #expect(formatter.format("1234567") == "+1(234)56-7")
        #expect(formatter.format("12345677") == "+1(234)56-77-")
        #expect(formatter.format("12345678") == "+1(234)56-7")
        #expect(formatter.format("123456778") == "+1(234)56-77-8")
    }
    
    @Test func testFormatString_withDigitPlaceholders_mixedMode() {
        let formatter = AKNumericFormatter.formatter(
            mask: "+1(xxx)xx-77-xx",
            placeholder: Character("x"),
            mode: .mixed
        )
        
        #expect(formatter.format("1") == "+1(")
        #expect(formatter.format("2") == "+1(2")
        #expect(formatter.format("23") == "+1(23")
        #expect(formatter.format("123") == "+1(23")
        #expect(formatter.format("123456") == "+1(234)56-77-")
        #expect(formatter.format("1234567") == "+1(234)56-77-")
        #expect(formatter.format("12345677") == "+1(234)56-77-")
        #expect(formatter.format("12345678") == "+1(234)56-77-8")
        #expect(formatter.format("123456778") == "+1(234)56-77-8")
        #expect(formatter.format("+afsf") == "")
    }


@Test func isFormatFulfilled() async throws {
    let formatter = AKNumericFormatter.formatter(mask: "**:**:**", placeholder: Character("*"))
    #expect(!formatter.isFormatFulfilled("12:"))
    #expect(!formatter.isFormatFulfilled("12:34:*6"))
    #expect(!formatter.isFormatFulfilled("12:34x56"))
    #expect(formatter.isFormatFulfilled("12:34:56"))
    #expect(!formatter.isFormatFulfilled("12:34:56:"))
}

@Test
func unfixedDigits() async throws {
    let formatter = AKNumericFormatter.formatter(mask: "+1(xxx)xx-77-xx", placeholder: Character("x"))
    #expect(throws: Never.self) { try formatter.unfixedDigits(string: "+1(234)56-77-89") == "2345689" }
    #expect(throws: AKNumericFormatter.FormatError.notCorrespondingToFormat.self) { try formatter.unfixedDigits(string: "+1(234)56-77-8999") == "2345689" }
}
