import Foundation

extension String {
    var trimmingPercentageValues: String {
        let regex = #"([0-9]*[ ]*%)"#
        
        var trimmedString = self
        while true {
            let groups = trimmedString.capturedGroups(using: regex)
            guard let percentageSubstring = groups.first else {
                break
            }
            
            trimmedString = trimmedString.replacingOccurrences(of: percentageSubstring, with: "")
        }
        return trimmedString
    }
    
    var hasBothKjAndKcal: Bool {
        let regex = #"^.*[0-9]+[ ]*kj.*[0-9]+[ ]*kcal.*$|^.*[0-9]+[ ]*kcal.*[0-9]+[ ]*kj.*$"#
        return self.matchesRegex(regex)
    }
}

extension String {

    var valueSubstringAtStart: String? {
        //TODO: Modularize this and substringUpToFirstNumeral handling not capturing the entire strings with a workaround
        let regex = Value.Regex.atStartOfString
        let groups = trimmingWhitespaces.capturedGroups(using: regex, allowCapturingEntireString: true)
        let substring: String?
        if groups.count > 1 {
            substring = groups[1]
        } else if groups.count == 1 {
            substring = groups[0]
        } else {
            substring = nil
        }
        return substring?.trimmingWhitespaces
    }

    var numberSubstringAtStart: String? {
        let regex = #"^([0-9]+[0-9.:,\/]*)"#
        let groups = trimmingWhitespaces.capturedGroups(using: regex, allowCapturingEntireString: true)
        let substring: String?
        if groups.count > 1 {
            substring = groups[1]
        } else if groups.count == 1 {
            substring = groups[0]
        } else {
            substring = nil
        }
        return substring?.trimmingWhitespaces
    }
    
    var containsWords: Bool {
        matchesRegex(#"[A-z]+"#)
    }
    
    var unitSubstringAtStart: String? {
        let units = NutritionUnit.allUnits.map{$0}.joined(separator: "|")
        let regex = #"^(\#(units))(?: |\(|\)|;|$)"#
        let groups = trimmingWhitespaces.capturedGroups(using: regex, allowCapturingEntireString: true)
        let substring: String?
        if groups.count > 1 {
            substring = groups[1]
        } else if groups.count == 1 {
            substring = groups[0]
        } else {
            substring = nil
        }
        return substring?.trimmingWhitespaces
    }

    var servingsPerContainerName: String? {
        guard let regex = Attribute.servingsPerContainerAmount.regex else {
            return nil
        }
        let groups = trimmingWhitespaces.capturedGroups(using: regex, allowCapturingEntireString: true)
        let substring: String?
        if groups.count > 1 {
            substring = groups[1]
        } else {
            substring = nil
        }
        return substring?.trimmingWhitespaces
    }

    var servingAttributeSubstringAtStart: String? {
        return nil
    }

    var substringUpToFirstNumeral: String? {
        let regex = #"^([0-9]*[^0-9\n]+)[0-9]?.*$"#
        let groups = trimmingWhitespaces.capturedGroups(using: regex, allowCapturingEntireString: true)
        let substring: String?
        if groups.count > 1 {
            substring = groups[1]
        } else if groups.count == 1 {
            substring = groups[0]
        } else {
            substring = nil
        }
        
        /// **Heuristic** for when we may have cut out a Vitamin such as `Vitamin B6`
        if let substring = substring {
            let remainder = self.replacingFirstOccurrence(of: substring, with: "")
            /// Matches B6
            if substring.matchesRegex("vitamin b$"), remainder.matchesRegex("^6( |$)") {
                return "\(substring)6"
            }
        }
        
        return substring?.trimmingWhitespaces
    }
    
    var substringUpToFirstNumeral_experimental: String? {
        guard let index = indexOfFirstNumeral else { return self }
        return String(prefix(index)).trimmingWhitespaces
    }
    
    var trimmingWhitespaces: String {
        trimmingCharacters(in: .whitespaces)
    }
}

extension String {
    var containsServingAttribute: Bool {
        for attribute in Attribute.allCases.filter({$0.isServingAttribute}) {
            if let regex = attribute.regex, lowercased().matchesRegex(regex) {
                return true
            }
        }
        return false
    }
}

//
extension String {
    var indexOfFirstNumeral: Int? {
        guard let firstNumeral = firstNumeral,
              let range: Range<String.Index> = range(of: firstNumeral)
        else { return nil }
        
        let index: Int = distance(from: startIndex, to: range.lowerBound)
        return index
    }
    
    var firstNumeral: String? {
        let regex = #"(?:^|\b\s+|\(|<)([0-9]+[0-9./\%]*)\s*"#
        let groups = trimmingWhitespaces.capturedGroups(using: regex, allowCapturingEntireString: true)
        let substring: String?
        if groups.count > 1 {
            substring = groups[1]
        } else if groups.count == 1 {
            substring = groups[0]
        } else {
            substring = nil
        }
        return substring?.trimmingWhitespaces
    }
}
