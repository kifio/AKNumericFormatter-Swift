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
        
        guard let numberIndex = mask.firstIndex(where: { $0.isDigit }) else {
            return mask.firstIndex(of: placeholder)
        }
        
        guard let placeholderIndex = mask.firstIndex(of: placeholder) else {
            return nil
        }
        
        return min(placeholderIndex, numberIndex)
    }
    
    func format(_ string: String) -> String {
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
    
    func isFormatFulfilled(_ string: String) -> Bool {
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
