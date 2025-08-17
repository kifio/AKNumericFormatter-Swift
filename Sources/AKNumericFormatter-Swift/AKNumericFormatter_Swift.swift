// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

final class AKNumericFormatter {
    
    enum Mode: Int {
        case strict
        case fillIn
        case mixed
    }

    enum FormatError: Error {
        case notCorrespondingToFormat
    }
    
    var mode: AKNumericFormatter.Mode
    var mask: String
    var placeholder: Character
    
    private init(mask: String, placeholder: Character, mode: AKNumericFormatter.Mode) {
        self.mask = mask
        self.placeholder = placeholder
        self.mode = mode
    }
    
    class func format(
        string: String,
        mask: String,
        placeholder: Character,
        mode: AKNumericFormatter.Mode = .strict
    ) -> String {
        formatter(mask: mask, placeholder: placeholder, mode: mode).format(string)
    }
    
    class func formatter(
        mask: String,
        placeholder: Character,
        mode: AKNumericFormatter.Mode = .strict
    ) -> AKNumericFormatter {
        AKNumericFormatter(mask: mask, placeholder: placeholder, mode: mode)
    }
    
    func indexOfFirstDigitOrPlaceholderInMask() -> String.Index? {
        
        guard let numberIndex = mask.firstIndex(where: { $0.isWholeNumber }) else {
            return mask.firstIndex(of: placeholder)
        }
        
        guard let placeholderIndex = mask.firstIndex(of: placeholder) else {
            return nil
        }
        
        return min(placeholderIndex, numberIndex)
    }
    
    func format(_ string: String) -> String {
        let onlyDigitsString = string.stringContainingOnlyDecimalDigits()
        guard !onlyDigitsString.isEmpty else {
            return ""
        }
        
        var formattedString = ""
        var digitIndex = onlyDigitsString.startIndex
        
        for maskCharacter in mask {
            if maskCharacter == placeholder {
                if digitIndex < onlyDigitsString.endIndex {
                    formattedString.append(onlyDigitsString[digitIndex])
                    digitIndex = onlyDigitsString.index(after: digitIndex)
                } else {
                    break
                }
            } else if mode != .fillIn, maskCharacter.isNumber {
                if digitIndex < onlyDigitsString.endIndex,
                   maskCharacter == onlyDigitsString[digitIndex] {
                    formattedString.append(maskCharacter)
                    digitIndex = onlyDigitsString.index(after: digitIndex)
                } else if mode == .mixed {
                    formattedString.append(maskCharacter)
                } else {
                    break
                }
            } else {
                formattedString.append(maskCharacter)
            }
        }
        
        guard !formattedString.stringContainingOnlyDecimalDigits().isEmpty else {
            return ""
        }
        
        return formattedString
    }
    
    func isFormatFulfilled(_ string: String) -> Bool {
        guard string.count == mask.count else {
            return false
        }
        
        for index in string.indices {
            let isMaskedCharacter = string[index].isWholeNumber && mask[index] == placeholder
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
            } else if string[index].isWholeNumber && mask[index] == placeholder {
                out.append(string[index])
            } else {
                throw FormatError.notCorrespondingToFormat
            }
        }
        
        return String(out)

    }
    
    func fillInMask(with digits: String) throws -> String {
        try AKNumericFormatter.format(string: digits, mask: self.mask, placeholder: placeholder, mode: .fillIn)
    }
}

extension String {
    func stringContainingOnlyDecimalDigits() -> String {
        let decimalDigitCharacterSet = CharacterSet.decimalDigits
        return String(self.unicodeScalars.filter { decimalDigitCharacterSet.contains($0) })
    }
}
