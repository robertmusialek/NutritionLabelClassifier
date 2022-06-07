import Foundation

public enum Attribute: String, CaseIterable {
    
    case nutritionFacts
    
    //MARK: - Serving
    case servingAmount                 /// Double
    case servingUnit                  /// NutritionUnit
    case servingUnitSize              /// String
    case servingEquivalentAmount       /// Double
    case servingEquivalentUnit        /// NutritionUnit
    case servingEquivalentUnitSize    /// String

    case servingsPerContainerAmount
    case servingsPerContainerName

    //MARK: - Header
    /// Header type for column 1 and 2, which indicates if they are a `per100g` or `perServing` column
    case headerType1
    case headerType2

    /// Header serving attributes which gets assigned to whichever column has the `perServing` type
    case headerServingAmount
    case headerServingUnit
    case headerServingUnitSize
    case headerServingEquivalentAmount
    case headerServingEquivalentUnit
    case headerServingEquivalentUnitSize

    //MARK: - Nutrient
    case energy
    
    case protein
    
    case carbohydrate
    case dietaryFibre
    case gluten
    case sugar
    case addedSugar
    case starch
    
    case fat
    case saturatedFat
    case polyunsaturatedFat
    case monounsaturatedFat
    case transFat
    case cholesterol
    
    case salt
    case sodium
    case calcium
    case iron
    case potassium
    case cobalamin
    case magnesium
    
    case vitaminA
    case vitaminC
    case vitaminD
    case vitaminB6
    
    
    public var conflictingAttributes: [Attribute] {
        switch self {
        case .servingUnit:
            return [.servingUnitSize]
        case .servingUnitSize:
            return [.servingUnit]
        case .servingEquivalentUnit:
            return [.servingEquivalentUnitSize]
        case .servingEquivalentUnitSize:
            return [.servingEquivalentUnit]
        case .headerServingUnit:
            return [.headerServingUnitSize]
        case .headerServingUnitSize:
            return [.headerServingUnit]
        case .headerServingEquivalentUnit:
            return [.headerServingEquivalentUnitSize]
        case .headerServingEquivalentUnitSize:
            return [.headerServingEquivalentUnit]
        default:
            return []
        }
    }
    
    public var isHeaderAttribute: Bool {
        switch self {
        case .headerServingAmount, .headerServingUnit, .headerServingUnitSize, .headerServingEquivalentAmount, .headerServingEquivalentUnit, .headerServingEquivalentUnitSize, .headerType1, .headerType2:
            return true
        default:
            return false
        }
    }
    public var isServingAttribute: Bool {
        switch self {
        case .servingAmount, .servingUnit, .servingUnitSize, .servingEquivalentAmount, .servingEquivalentUnit, .servingEquivalentUnitSize, .servingsPerContainerName, .servingsPerContainerAmount:
            return true
        default:
            return false
        }
    }
    
    public var expectsDouble: Bool {
        switch self {
        case .servingAmount, .servingEquivalentAmount, .servingsPerContainerAmount, .headerServingAmount, .headerServingEquivalentAmount:
            return true
        default:
            return false
        }
    }
    
    public var expectsHeaderType: Bool {
        switch self {
        case .headerType1, .headerType2:
            return true
        default:
            return false
        }
    }
    public var expectsNutritionUnit: Bool {
        switch self {
        case .servingUnit, .servingEquivalentUnit, .headerServingUnit, .headerServingEquivalentUnit:
            return true
        default:
            return false
        }
    }
    
    public var expectsString: Bool {
        switch self {
        case .servingUnitSize, .servingEquivalentUnitSize, .servingsPerContainerName, .headerServingUnitSize, .headerServingEquivalentUnitSize:
            return true
        default:
            return false
        }
    }
    
    public var isIrrelevant: Bool {
        switch self {
        case .nutritionFacts:
            return true
        default:
            return false
        }
    }
    
    public var isNutrientAttribute: Bool {
        !isHeaderAttribute && !isServingAttribute && !isIrrelevant
    }

    
    var parentAttribute: Attribute? {
        switch self {
        case .saturatedFat, .polyunsaturatedFat, .monounsaturatedFat, .transFat, .cholesterol:
            return .fat
        case .dietaryFibre, .gluten, .sugar, .addedSugar, .starch:
            return .carbohydrate
        case .sodium:
            return .salt
        default:
            return nil
        }
    }
    func supportsUnit(_ unit: NutritionUnit) -> Bool {
        supportedUnits.contains(unit)
    }
    
    var defaultUnit: NutritionUnit? {
        supportedUnits.first
    }
    
    var supportsMultipleColumns: Bool {
        switch self {
        case .servingsPerContainerAmount, .servingsPerContainerName:
            return false
        default:
            return true
        }
    }
    
    /// For values like `servingsPerContainerAmount` and `addedSugar` which allows extracting preceding values like the following:
    /// `40 Servings Per Container`
    /// `Includes 4g Added Sugar`
    var supportsPrecedingValue: Bool {
        switch self {
        case .servingsPerContainerAmount, .servingsPerContainerName:
            return true
        default:
            return false
        }
    }
    
    var isNutrient: Bool {
        !isServingAttribute && !isHeaderAttribute
    }
    
    var supportedUnits: [NutritionUnit] {
        switch self {
        case .energy:
            return [ .kj, .kcal]
        case .protein, .carbohydrate, .fat, .salt:
            return [.g]
        case .dietaryFibre, .saturatedFat, .polyunsaturatedFat, .monounsaturatedFat, .transFat, .cholesterol, .sugar, .addedSugar, .gluten, .starch:
            return [.g, .mg, .mcg]
        case .sodium, .calcium, .iron, .potassium, .magnesium, .cobalamin, .vitaminA, .vitaminC, .vitaminD, .vitaminB6:
            return [.mg, .mcg, .p, .g]
        case .servingAmount:
            return [.cup, .g, .mcg, .mg]
        default:
            return []
        }
    }
    
    func supportsServingArtefact(_ servingArtefact: ServingArtefact) -> Bool {
        switch self {
        case .servingsPerContainerName, .servingUnitSize, .servingEquivalentUnitSize:
            return servingArtefact.string != nil
        case .servingAmount, .servingEquivalentAmount, .servingsPerContainerAmount:
            return servingArtefact.double != nil
        case .servingUnit, .servingEquivalentUnit:
            return servingArtefact.unit != nil
        default:
            return false
        }
    }
    
    var nextAttributes: [Attribute]? {
        switch self {
        case .servingAmount:
            return [.servingUnit, .servingUnitSize]
        case .servingUnit, .servingUnitSize:
            return [.servingEquivalentAmount]
        case .servingEquivalentAmount:
            return [.servingEquivalentUnit, .servingEquivalentUnitSize]
        default:
            return nil
        }
    }
    
    var regex: String? {
        switch self {
        case .servingsPerContainerAmount:
            return #"(?:servings |serving5 |)per (container|package|tub|pot)"#
        case .servingAmount:
            return #"(serving size|size:|dose de referência)"#
        case .nutritionFacts:
            return #"Nutrition Facts"#
        case .energy:
            return #"^.*(energy|calories|energie|kcal).*$"#
            
        case .protein:
            return #"(protein|proteine)"#
            
        case .carbohydrate:
            return #".*(carb|glucides|hydrate).*"#
        case .dietaryFibre:
            return #"(dietary |)fib(re|er)"#
        case .gluten:
            return #"gluten"#
        case .starch:
            return #"starch"#

        case .fat:
            return Regex.fat
        case .saturatedFat:
            return Regex.saturatedFat
        case .monounsaturatedFat:
            return Regex.monounsaturatedFat
        case .polyunsaturatedFat:
            return Regex.polyunsaturatedFat
        case .transFat:
            return Regex.transFat
        case .cholesterol:
            return Regex.cholesterol
            
        case .salt:
            return #"(salt|salz|sel)"#
        case .sodium:
            return #"sodium"#
        case .sugar:
            return Regex.sugar
        case .addedSugar:
            return Regex.addedSugar
        case .calcium:
            return #"calcium"#
        case .iron:
            return #"(^| )iron"#
        case .potassium:
            return #"potas"#
        case .magnesium:
            return #"magnesium"#
            
        case .cobalamin: /// Vitamin B12
            return #"cobalamin"#
        case .vitaminA:
            return Regex.vitamin("a")
        case .vitaminC:
            return Regex.vitamin("c")
        case .vitaminD:
            return Regex.vitamin("d")
        case .vitaminB6:
            return Regex.vitamin("b6")

        default:
            return nil
        }
    }
    
    var supportsUnitLessValues: Bool {
        switch self {
        case .servingsPerContainerAmount, .servingsPerContainerName:
            return true
        default:
            return false
        }
    }
    
    init?(fromString string: String) {
        
        var pickedAttribute: Attribute? = nil
        for attribute in Self.allCases {
            guard let regex = attribute.regex else { continue }
            if string.cleanedAttributeString.matchesRegex(regex) {
                guard pickedAttribute == nil else {
                    /// Fail strings that contain more than one match (since the order shouldn't dictate what we choose)
                    return nil
                }
                pickedAttribute = attribute
            }
        }
        if let pickedAttribute = pickedAttribute {
            self = pickedAttribute
        } else {
            return nil
        }
    }
    
    var isValueBased: Bool {
        switch self {
        case .servingAmount, .servingUnit, .servingUnitSize, .servingEquivalentAmount, .servingEquivalentUnit, .servingEquivalentUnitSize, .servingsPerContainerAmount, .servingsPerContainerName:
            return false
        default:
            return true
        }
    }
    
    struct Regex {
        static let amountPerServing = #"amount per serving"#
        static let amountPer100g = #"amount per 100[ ]*g"#
        static let amountPer100ml = #"amount per 100[ ]*ml"#

        static let calories = #"calories"#
        
        static let sugar = #"^(?=^.*(sugar|sucres|zucker|zuccheri).*$)(?!^.*\#(addedSugar).*$).*$"#
        static let addedSugar = #"added sugar(s|)"#
        
        static let fat = #"^(?=^.*(fa(t|i)|fett|grassi|lípidos).*$)(?!\#(saturatedFat))(?!\#(transFat))(?!\#(polyunsaturatedFat))(?!\#(monounsaturatedFat)).*$"#
        static let saturatedFat = #"^.*(saturated|of which saturates|saturi|saturados).*$"#
        static let transFat = #"^.*trans.*$"#
        static let monounsaturatedFat = #"^.*mono(-|)unsaturat.*$"#
        static let polyunsaturatedFat = #"^.*poly(-|)unsaturat.*$"#
        static let cholesterol = #"cholesterol"#
        
        static func vitamin(_ letter: String) -> String {
            #"vit(amin[ ]+|\.[ ]*|[ ]+)\#(letter)"#
        }
    }
}

extension String {
    var cleanedAttributeString: String {
        var cleaned = trimmingWhitespaces
            .lowercased()

        /// Fix Vision misreads
        cleaned = cleaned.replacingOccurrences(of: "serving5", with: "servings")
        if cleaned.hasPrefix("i container") {
            cleaned = cleaned.replacingFirstOccurrence(of: "i container", with: "1 container")
        }
        cleaned = cleaned.replacingOccurrences(of: "l tbsp", with: "1 tbsp")
        
        return cleaned
    }
}

extension Attribute: Identifiable {
    public var id: RawValue { rawValue }
}

extension Attribute {
    static func attributes(in string: String) -> [Attribute] {
        for attribute in Attribute.allCases {
            guard let regex = attribute.regex else { continue }
            if string.matchesRegex(regex) {
                return [attribute]
            }
        }
        return []
    }
}


extension Attribute: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nutritionFacts:
            return "Nutrition Facts"
        case .servingAmount:
            return "Serving Amount"
        case .servingUnit:
            return "Serving Unit"
        case .servingUnitSize:
            return "Serving Unit Size"
        case .servingEquivalentAmount:
            return "Serving Equivalent Amount"
        case .servingEquivalentUnit:
            return "Serving Equivalent Unit"
        case .servingEquivalentUnitSize:
            return "Serving Equivalent Unit Size"
        case .servingsPerContainerAmount:
            return "Servings Per Container Amount"
        case .servingsPerContainerName:
            return "Servings Per Container Name"
        case .headerType1:
            return "Header Type 1"
        case .headerType2:
            return "Header Type 2"
        case .headerServingAmount:
            return "Header Serving Amount"
        case .headerServingUnit:
            return "Header Serving Unit"
        case .headerServingUnitSize:
            return "Header Serving Unit Name"
        case .headerServingEquivalentAmount:
            return "Header Serv.Equiv. Amount"
        case .headerServingEquivalentUnit:
            return "Header Serv.Equiv. Unit"
        case .headerServingEquivalentUnitSize:
            return "Header Serv.Equiv. Unit Name"
            
        case .energy:
            return "Energy"
        case .protein:
            return "Protein"
        case .carbohydrate:
            return "Carbohydrate"
        case .dietaryFibre:
            return "Dietary Fibre"
        case .gluten:
            return "Gluten"
        case .sugar:
            return "Total Sugars"
        case .addedSugar:
            return "Added Sugars"
        case .starch:
            return "Starch"
        case .fat:
            return "Fat"
        case .saturatedFat:
            return "Saturated Fat"
        case .polyunsaturatedFat:
            return "Polyunsaturated Fat"
        case .monounsaturatedFat:
            return "Monounsaturated Fat"
        case .transFat:
            return "Trans Fat"
        case .cholesterol:
            return "Cholesterol"
        case .salt:
            return "Salt"
        case .sodium:
            return "Sodium"
        case .calcium:
            return "Calcium"
        case .iron:
            return "Iron"
        case .magnesium:
            return "Magnesium"
        case .cobalamin:
            return "Cobalamin"
        case .potassium:
            return "Potassium"
        case .vitaminA:
            return "Vitamin A"
        case .vitaminC:
            return "Vitamin C"
        case .vitaminD:
            return "Vitamin D"
        case .vitaminB6:
            return "Vitamin B6"
        }
    }
}
