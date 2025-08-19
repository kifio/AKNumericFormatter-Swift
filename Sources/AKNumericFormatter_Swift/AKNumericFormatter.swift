import UIKit
import ObjectiveC

public final class AKNumericFormatter {
    
    public enum Mode: Int {
        case strict
        case fillIn
        case mixed
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
    
    func indexOfFirstDigitOrPlaceholderInMask() -> Int {
        let numberIndex: Int? = mask.enumerated().first { index, character in character.isDigit }?.offset
        let placeholderIndex: Int? = mask.enumerated().first { index, character in character == placeholder }?.offset
        
        guard let numberIndex, let placeholderIndex else {
            return placeholderIndex ?? -1
        }
        
        return min(placeholderIndex, numberIndex)
    }

    func unfixedDigits(string: String) -> String? {
        guard string.count <= mask.count else {
            return nil
        }
        
        var out = Array<Character>()
        out.reserveCapacity(string.count)
        
        for index in string.indices {
            if string[index] == mask[index] {
                continue
            } else if string[index].isDigit && mask[index] == placeholder {
                out.append(string[index])
            } else {
                return nil
            }
        }
        
        return String(out)
    }

    func minPrefixLengthContainingCharsCount(
        _ source: any BidirectionalCollection<Character>,
        _ offsetDigitsCount: inout Int
    ) -> Int {
        var result = 0
        
        source.forEach { character in
            if offsetDigitsCount == 0 {
                return
            }
            
            result += 1
            
            if character.isDigit {
                offsetDigitsCount -= 1
            }
        }
        
        return result > 0 ? result : -1
    }
}

extension Character {
    var isDigit: Bool { isWholeNumber && isASCII }
}

extension UITextField {

    @MainActor private static var NumericFormatterKey: UInt8 = 0
    @MainActor private static var HandleDeleteBackwardsKey: UInt8 = 1
    @MainActor private static var IsFormattingKey: UInt8 = 2
    
    public var numericFormatter: AKNumericFormatter? {
        get {
            return objc_getAssociatedObject(self, &UITextField.NumericFormatterKey) as? AKNumericFormatter
        }
        set {
            let originalSelector = #selector(deleteBackward)
            let swizzledSelector = #selector(deleteBackwardSwizzle)
            if let originalMethod = class_getInstanceMethod(UITextField.self, originalSelector),
               let swizzledMethod = class_getInstanceMethod(UITextField.self, swizzledSelector) {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }

            objc_setAssociatedObject(self, &UITextField.NumericFormatterKey, newValue, .OBJC_ASSOCIATION_RETAIN)
            if newValue != nil {
                self.addTarget(self, action: #selector(handleTextChanged(_:)), for: .editingChanged)
            } else {
                self.removeTarget(self, action: #selector(handleTextChanged(_:)), for: .editingChanged)
            }
        }
    }
    
    var handleDeleteBackwards: Bool {
        get {
            return (objc_getAssociatedObject(self, &UITextField.HandleDeleteBackwardsKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &UITextField.HandleDeleteBackwardsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var isFormatting: Bool {
        get {
            return (objc_getAssociatedObject(self, &UITextField.IsFormattingKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &UITextField.IsFormattingKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
        
        defer {
            isFormatting = false;
            handleDeleteBackwards = false
        }
        
        guard
            var text,
            var selectedTextRange
        else { return }
        
        // Save caret position
        let modifiedSubsting = if handleDeleteBackwards {
            text.prefix(offset(from: beginningOfDocument, to: selectedTextRange.start))
        } else {
            text.suffix(offset(from: selectedTextRange.end, to: endOfDocument))
        }
                
        // Format text
        let newText = formatter.format(text)
        
        if text != newText {
            self.text = newText
            sendActions(for: .editingChanged)
        }

        // Restore caret position
        text = self.text ?? ""
        
        var newCaretOffset: Int = 0
        var offsetDigitsCount = modifiedSubsting.filter { $0.isDigit }.count

        if handleDeleteBackwards {
            newCaretOffset = formatter.minPrefixLengthContainingCharsCount(text, &offsetDigitsCount)
        } else {
            newCaretOffset = text.count - formatter.minPrefixLengthContainingCharsCount(text.reversed(), &offsetDigitsCount)
        }
        
        if newCaretOffset < formatter.indexOfFirstDigitOrPlaceholderInMask() {
            newCaretOffset = text.count
        }
        
        if newCaretOffset < text.count {
            
            let maskHasDigitsAfterCaret = formatter.mask
                .dropFirst(newCaretOffset)
                .contains(where: { $0.isDigit } )
                        
            let textHasOnlyThrashAfterCaret = text
                .dropFirst(newCaretOffset)
                .contains(where: { !$0.isDigit } )
            
            if textHasOnlyThrashAfterCaret || maskHasDigitsAfterCaret {
                self.text = String(text.prefix(newCaretOffset))
                sendActions(for: .editingChanged)
            }
        }
        
        if
            let newPosition = position(from: beginningOfDocument, offset: newCaretOffset),
            let textRange = textRange(from: newPosition, to: newPosition)
        {
            selectedTextRange = textRange
        }
    }
    
    func formatCurrentText() {
        guard numericFormatter != nil else { return }
        handleDeleteBackwards = false
        handleTextChanged(nil)
    }
    
    public func alertDeleteBackwards() {
        handleDeleteBackwards = true
    }
}
