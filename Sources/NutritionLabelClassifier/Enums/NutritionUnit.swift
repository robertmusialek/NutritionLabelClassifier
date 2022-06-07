import Foundation

extension NutritionUnit: CustomStringConvertible {
    public var description: String {
        switch self {
        case .mg:
            return "mg"
        case .kj:
            return "kJ"
        case .mcg:
            return "mcg"
        case .kcal:
            return "kcal"
        case .p:
            return "%"
        case .g:
            return "g"
        case .cup:
            return "cup"
        case .oz:
            return "oz"
        case .ml:
            return "ml"
        case .tbsp:
            return "tbsp"
        }
    }
}

public enum NutritionUnit: Int, CaseIterable {
    case kcal
    case cup
    case mcg //TODO: Recognize `ug` as an alternative and remove it
    case mg //TODO: Recognize `mq` as a typo
    case kj
    case p
    case g
    case oz
    case ml
    case tbsp

    init?(string: String) {
        for unit in Self.allCases {
            if unit.possibleUnits.contains(string) {
                self = unit
                return
            }
        }
        return nil
    }
    
    var isAllowedInHeader: Bool {
        switch self {
        case .kcal, .mcg, .mg, .kj, .p:
            return false
        default:
            return true
        }
    }
    
    var regex: String? {
        switch self {
        case .g:
            return "^g$"
        case .oz:
            return "^oz$"
        case .mg:
            return "^(mg|mq)$"
        case .kj:
            return "^kj$"
        case .mcg:
            return "^(ug|mcg)$"
        case .kcal:
            return "^(k|)cal(s|ories|)$"
        case .p:
            return "^%$"
        case .cup:
            return "^cup(s|)$"
        case .ml:
            return "^ml$"
        case .tbsp:
            return "^(tbsp|tablespoon(s|))$"
        }
    }
    
    var possibleUnits: [String] {
        switch self {
        case .g:
            return ["g", "c"]
        case .oz:
            return ["oz"]
        case .mg:
            return ["mg", "mq"]
        case .kj:
            return ["kj", "kJ", "kilojules"]
        case .mcg:
            return ["mcg", "ug"]
        case .kcal:
            return ["kcal", "cal", "calorie", "calories"]
        case .p:
            return ["%"]
        case .cup:
            return ["cup", "cups"]
        case .ml:
            return ["ml", "mL"]
        case .tbsp:
            return ["tbsp", "tablespoon", "tablespoons"]
        }
    }
    
    static var allUnits: [String] {
        var allUnits: [String] = []
        for unit in allCases {
            allUnits.append(contentsOf: unit.possibleUnits)
        }
        return allUnits
    }
    
    static var allUnitsRegexOptions = allUnits.joined(separator: "|")
}
