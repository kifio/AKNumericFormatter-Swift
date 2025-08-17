import UIKit
import ObjectiveC

public final class AKNumericFormatter {
    
    @MainActor fileprivate static var NumericFormatterKey: UInt8 = 0
    @MainActor fileprivate static var HandleDeleteBackwardsKey: UInt8 = 1
    @MainActor fileprivate static var IsFormattingKey: UInt8 = 2
    
    public enum Mode: Int {
        case strict
        case fillIn
        case mixed
    }

    enum FormatError: Error {
        case notCorrespondingToFormat
    }
    
    public let mode: AKNumericFormatter.Mode
    public let mask: String
    public let placeholder: Character
    
    init(mask: String, placeholder: Character, mode: AKNumericFormatter.Mode) {
        self.mask = mask
        self.placeholder = placeholder
        self.mode = mode
    }
    
    public class func format(
        string: String,
        mask: String,
        placeholder: Character,
        mode: AKNumericFormatter.Mode = .strict
    ) -> String {
        formatter(mask: mask, placeholder: placeholder, mode: mode).format(string)
    }
    
    public class func formatter(
        mask: String,
        placeholder: Character,
        mode: AKNumericFormatter.Mode = .strict
    ) -> AKNumericFormatter {
        AKNumericFormatter(mask: mask, placeholder: placeholder, mode: mode)
    }
    
    func indexOfFirstDigitOrPlaceholderInMask() -> Int {
        let numberIndex: Int? = mask.enumerated().first { index, character in character.isDigit }?.offset
        let placeholderIndex: Int? = mask.enumerated().first { index, character in character == placeholder }?.offset
        
        guard let numberIndex, let placeholderIndex else {
            return placeholderIndex ?? -1
        }
        
        return min(placeholderIndex, numberIndex)
    }
    
    public func format(_ string: String) -> String {
        var onlyDigits: [Character] = string.filter { $0.isDigit }
        
        guard !onlyDigits.isEmpty else {
            return ""
        }
        
        var out = [Character]()
        
        for maskCharacter in mask {
            if maskCharacter == placeholder {
                if !onlyDigits.isEmpty {
                    out.append(onlyDigits.removeFirst())
                } else {
                    break
                }
            } else if mode != .fillIn, maskCharacter.isDigit {
                if !onlyDigits.isEmpty, maskCharacter == onlyDigits.first {
                    out.append(maskCharacter)
                    onlyDigits.removeFirst()
                } else if mode == .mixed {
                    out.append(maskCharacter)
                } else {
                    break
                }
            } else {
                out.append(maskCharacter)
            }
        }
        
        guard out.first(where: { $0.isDigit }) != nil else {
            return ""
        }
        
        return String(out)
    }
    
    public func isFormatFulfilled(_ string: String) -> Bool {
        guard string.count == mask.count else {
            return false
        }
        
        for index in string.indices {
            let isMaskedCharacter = string[index].isDigit && mask[index] == placeholder
            let isUnmaskedCharacter = string[index] != placeholder && string[index] == mask[index]
            
            if !isMaskedCharacter && !isUnmaskedCharacter {
                return false
            }
        }
        
        return true
    }

    func unfixedDigits(string: String) throws -> String {
        guard string.count <= mask.count else {
            throw FormatError.notCorrespondingToFormat
        }
        
        var out = Array<Character>()
        out.reserveCapacity(string.count)
        
        for index in string.indices {
            if string[index] == mask[index] {
                continue
            } else if string[index].isDigit && mask[index] == placeholder {
                out.append(string[index])
            } else {
                throw FormatError.notCorrespondingToFormat
            }
        }
        
        return String(out)

    }
    
    func fillInMask(with digits: String) throws -> String {
        AKNumericFormatter.format(string: digits, mask: self.mask, placeholder: placeholder, mode: .fillIn)
    }
}

extension Character {
    var isDigit: Bool { isWholeNumber && isASCII }
}

extension UITextField {
    
    public var numericFormatter: AKNumericFormatter? {
        get {
            return objc_getAssociatedObject(self, &AKNumericFormatter.NumericFormatterKey) as? AKNumericFormatter
        }
        set {
            let originalSelector = #selector(deleteBackward)
            let swizzledSelector = #selector(deleteBackwardSwizzle)
            if let originalMethod = class_getInstanceMethod(UITextField.self, originalSelector),
               let swizzledMethod = class_getInstanceMethod(UITextField.self, swizzledSelector) {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }

            objc_setAssociatedObject(self, &AKNumericFormatter.NumericFormatterKey, newValue, .OBJC_ASSOCIATION_RETAIN)
            if newValue != nil {
                self.addTarget(self, action: #selector(handleTextChanged(_:)), for: .editingChanged)
            } else {
                self.removeTarget(self, action: #selector(handleTextChanged(_:)), for: .editingChanged)
            }
        }
    }
    
    var handleDeleteBackwards: Bool {
        get {
            return (objc_getAssociatedObject(self, &AKNumericFormatter.HandleDeleteBackwardsKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &AKNumericFormatter.HandleDeleteBackwardsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var isFormatting: Bool {
        get {
            return (objc_getAssociatedObject(self, &AKNumericFormatter.IsFormattingKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &AKNumericFormatter.IsFormattingKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    @objc func deleteBackwardSwizzle() {
        alertDeleteBackwards()
        // Call the original (swizzled) implementation
        deleteBackwardSwizzle()
    }
    
    @objc func handleTextChanged(_ sender: Any?) {
        guard !isFormatting, let formatter = self.numericFormatter else { return }
        isFormatting = true
        defer { isFormatting = false; handleDeleteBackwards = false }
        
        guard let text = self.text else { return }
        
        // Save caret position
        let caretHeadOffset = offset(from: beginningOfDocument, to: selectedTextRange?.start ?? endOfDocument)
        let caretTailOffset = offset(from: selectedTextRange?.end ?? beginningOfDocument, to: endOfDocument)
        var offsetDigitsCount: Int = 0
        if handleDeleteBackwards {
            offsetDigitsCount = text.prefix(caretHeadOffset).countDecimalDigits()
        } else {
            offsetDigitsCount = text.suffix(text.count - caretTailOffset).countDecimalDigits()
        }

        // Format text
        let newText = formatter.format(text)
        if text != newText {
            self.text = newText
            sendActions(for: .editingChanged)
        }

        // Restore caret position
        let restoredText = self.text ?? ""
        var newCaretOffset: Int = 0
        if handleDeleteBackwards {
            newCaretOffset = restoredText.minPrefixLengthContainingDecimalDigitsCount(offsetDigitsCount)
        } else {
            newCaretOffset = restoredText.count - restoredText.minSuffixLengthContainingDecimalDigitsCount(offsetDigitsCount)
        }
        if newCaretOffset < formatter.indexOfFirstDigitOrPlaceholderInMask() {
            newCaretOffset = restoredText.count
        }
        if newCaretOffset < restoredText.count {
            let decimalDigits = CharacterSet.decimalDigits
            let maskHasDigitsAfterCaret = formatter.mask.dropFirst(newCaretOffset).rangeOfCharacter(from: decimalDigits) != nil
            let textHasOnlyThrashAfterCaret = restoredText.dropFirst(newCaretOffset).rangeOfCharacter(from: decimalDigits) == nil
            if textHasOnlyThrashAfterCaret || maskHasDigitsAfterCaret {
                self.text = String(restoredText.prefix(newCaretOffset))
                sendActions(for: .editingChanged)
            }
        }
        if let newPosition = position(from: beginningOfDocument, offset: newCaretOffset),
           let textRange = textRange(from: newPosition, to: newPosition) {
            selectedTextRange = textRange
        }
    }
    
    func formatCurrentText() {
        guard numericFormatter != nil else { return }
        handleDeleteBackwards = false
        handleTextChanged(nil)
    }
    
    func alertDeleteBackwards() {
        handleDeleteBackwards = true
    }
}

// Helpers for counting decimal digits and prefix/suffix calculations
extension Substring {
    func countDecimalDigits() -> Int {
        return self.filter { $0.isDigit }.count
    }
}

extension String {

    func minPrefixLengthContainingDecimalDigitsCount(_ digitsCount: Int) -> Int {
        var remaining = digitsCount
        for (i, c) in self.enumerated() {
            if c.isWholeNumber {
                remaining -= 1
                if remaining == 0 { return i + 1 }
            }
        }
        return -1
    }
    
    func minSuffixLengthContainingDecimalDigitsCount(_ digitsCount: Int) -> Int {
        var remaining = digitsCount
        for (i, c) in self.reversed().enumerated() {
            if c.isWholeNumber {
                remaining -= 1
                if remaining == 0 { return i + 1 }
            }
        }
        return -1
    }
}
