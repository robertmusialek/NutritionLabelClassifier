import Foundation

public struct Value {
    public let amount: Double
    public var unit: NutritionUnit?
    
    init?(fromString string: String) {
        
        /// Special cases
        let str = string.trimmingWhitespaces.lowercased()
        if str == "nil" {
            self.amount = 0
            self.unit = .g
            return
        } else if str == "trace" {
            self.amount = 0.05
            self.unit = .g
            return
        }
        
        let groups = string.capturedGroups(using: Regex.fromString, allowCapturingEntireString: true)
        guard groups.count > 1 else {
            return nil
        }
        
        var cleanedAmount = groups[1]
            .replacingOccurrences(of: ":", with: ".") /// Fix Vision errors of misreading decimal places as `:`
        
        
        if cleanedAmount.matchesRegex(NumberRegex.usingCommaAsDecimalPlace) {
            cleanedAmount = cleanedAmount.replacingOccurrences(of: ",", with: ".")
        } else {
            /// It's been used as a thousand separator in that case
            cleanedAmount = cleanedAmount.replacingOccurrences(of: ",", with: "")
        }
        
        guard let amount = Double(cleanedAmount) else {
            return nil
        }
        self.amount = amount
        if groups.count == 3 {
            guard let unit = NutritionUnit(string: groups[2].lowercased().trimmingWhitespaces) else {
                return nil
            }
            self.unit = unit
        } else {
            self.unit = nil
        }
    }
    
    public init(amount: Double, unit: NutritionUnit? = nil) {
        self.amount = amount
        self.unit = unit
    }
    
    struct Regex {
        static let units = NutritionUnit.allUnits.map { #"[ ]*\#($0)"# }.joined(separator: "|")
        static let number = #"[0-9]+[0-9.:,]*"#
        static let atStartOfString = #"^(?:(\#(number)(?:(?:\#(units)(?: |\)|$))| |$)*(?: |\)|\/|$))|nil(?: |$)|trace(?: |$))"#
        static let atStartOfString_legacy2 = #"^(?:(\#(number)(?:(?:\#(units)(?: |\)|$))| |$))|nil(?: |$)|trace(?: |$))"#
        static let atStartOfString_legacy1 = #"^(\#(number)(?:(?:\#(units)(?: |\)|$))| |$))"#
        static let fromString = #"^(\#(number))(?:(\#(units)(?: |\)|$))| |\/|$)"#
        
        //TODO: Remove this
        static let standardPattern =
        #"^(?:[^0-9.:]*(?: |\()|^\/?)([0-9.:]+)[ ]*(\#(units))+(?: .*|\).*$|\/?$)$"#
    }
}

struct NumberRegex {
    /// Recognizes number in a string using comma as decimal place (matches `39,3` and `2,05` but not `2,000` or `1,2,3`)
    static let usingCommaAsDecimalPlace = #"^[0-9]*,[0-9][0-9]?([^0-9]|$)"#
    static let isFraction = #"^([0-9]+)\/([0-9]+)"#
}

extension Value: Equatable {
    public static func ==(lhs: Value, rhs: Value) -> Bool {
        lhs.amount == rhs.amount &&
        lhs.unit == rhs.unit
    }
}

extension Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(unit)
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        if let unit = unit {
            return "\(amount) \(unit.description)"
        } else {
            return "\(amount)"
        }
    }
}
