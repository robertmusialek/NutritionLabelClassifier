import Foundation

public enum Attribute: String, CaseIterable {
    
    case tableElementNutritionFacts
    case tableElementSkippable
    
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
    
    //MARK: Core Table Nutrients
    case protein
    
    case carbohydrate
    case gluten
    case sugar
    case addedSugar
    case polyols
    case starch

    case dietaryFibre
    case solubleFibre
    case insolubleFibre

    case fat
    case saturatedFat
    case polyunsaturatedFat
    case monounsaturatedFat
    case transFat
    case cholesterol
    
    case salt
    case sodium
    
    //MARK: Additional Table Nutrients (Usually at bottom)
    case calcium
    case iron
    case potassium
    case cobalamin
    case magnesium
    case thiamin
    case riboflavin
    case niacin
    case zinc
    
    case folate
    case folicAcid
    case vitaminA
    case vitaminC
    case vitaminD
    case vitaminB1
    case vitaminB6
    case vitaminB12
    
    var isCoreTableNutrient: Bool {
        switch self {
        case .protein, .carbohydrate, .gluten, .sugar, .addedSugar, .polyols, .starch, .dietaryFibre, .solubleFibre, .insolubleFibre, .fat, .saturatedFat, .polyunsaturatedFat, .monounsaturatedFat, .transFat, .cholesterol, .salt, .sodium:
            return true
        default:
            return false
        }
    }
    
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
    
    public var isTableAttribute: Bool {
        switch self {
        case .tableElementNutritionFacts:
            return true
        case .tableElementSkippable:
            return true
        default:
            return false
        }
    }
    
    public var isNutrientAttribute: Bool {
        !isHeaderAttribute && !isServingAttribute && !isTableAttribute
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
        case .tableElementNutritionFacts:
            return #"nutrition facts"#
        case .tableElementSkippable:
            return #"^(vitamins (&|and) minerals|of which|alimentaires|g)$"#
        case .servingsPerContainerAmount:
            return #"(?:servings |serving5 |)per (container|pack(age|)|tub|pot)"#
        case .servingAmount:
            return #"((serving size|size:|dose de referencia)|^size$)"#
        case .energy:
            return Regex.energy
            
        case .protein:
            return #"(protein|proteine|proteines)(?! (bar|bas))( |$)"#
            
        case .carbohydrate:
            return #".*(carb|glucide(s|)|(h|b)(y|v)drate).*"#
        case .dietaryFibre:
            return Regex.dietaryFibre
        case .solubleFibre:
            return Regex.solubleFibre
        case .insolubleFibre:
            return Regex.insolubleFibre
        case .polyols:
            return "(polyols|polioli)"
        case .gluten:
            return #"^.*gluten(?! (free|(b|d)evatten)).*$"#
        case .starch:
            return Regex.starch

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
            return #"(?<!less of )(salt|salz|[^A-z]sel|sare)([^,]|\/|$)"#
        case .sodium:
            return #"sodium"#
        case .sugar:
            return Regex.sugar
        case .addedSugar:
            return Regex.addedSugar
        case .calcium:
            return #"calcium(?! citrate)"#
        case .iron:
            return #"(^| )iron"#
        case .potassium:
            return #"potas"#
        case .magnesium:
            return #"magnesium"#
        case .zinc:
            return #"zinc"#
        case .thiamin:
            return #"thiamin"#
        case .riboflavin:
            return #"riboflavin"#
        case .niacin:
            return #"niacin"#
        
        case .folicAcid:
            return #"folic acid"#
        case .folate:
            return #"folate"#
            
        case .cobalamin: /// Vitamin B12
            return #"cobalamin"#
        case .vitaminA:
            return Regex.vitamin("a")
        case .vitaminC:
            return Regex.vitamin("c")
        case .vitaminD:
            return Regex.vitamin("d")
        case .vitaminB6:
            return Regex.vitamin("(b6|86)")
        case .vitaminB1:
            return Regex.vitamin("(b1|81)")
        case .vitaminB12:
            return Regex.vitamin("(b12|812)")
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
        
        static let energy_legacy = #"^(.*energy.*|.*energi.*|.*calories.*|.*energie.*|.*valoare energetica.*|y kcal)$"#
        static let energyOptions = [
            ".*energy.*", ".*energi.*", ".*calories.*", ".*energie.*", ".*valoare energetica.*", "y kcal"
        ]
        static let energyOnly = #"^(\#(energyOptions.joined(separator: "|")))$"#
        static let energyOutOfContext = #".*calories a day.*"#
        static let energy = #"^(?=\#(energyOnly))(?!\#(energyOutOfContext)).*$"#
//        static let energy = #"^(?=\#(energyOnly)).*$"#

        static let totalSugarOptions = [
            "sugar", "sucres", "zucker", "zuccheri", "dont sucres", "din care zaharuri", "azucares", "waarvan suikers", "sigar"
        ]
        
        static let totalSugar = #"^.*(\#(totalSugarOptions.joined(separator: "|")))([^,]|).*$"#
        static let addedSugar = #"^.*(added sugar(s|)|includes [0-9,.]+ (grams|g)).*$"#
        static let sugar = #"^(?=\#(totalSugar))(?!\#(addedSugar)).*$"#
        
        static let dietaryFibreOptions = [
            "(dietary |)fib(re|er)", "fibra", "voedingsvezel"
        ]
        static let solubleFibreOptions = [
            "(^|[ ])soluble fib(re|er)"
        ]
        static let insolubleFibreOptions = [
            "insoluble fib(re|er)"
        ]
        static let dietaryFibreOnly = #"^.*(\#(dietaryFibreOptions.joined(separator: "|"))).*$"#
        static let solubleFibre = #"^.*(\#(solubleFibreOptions.joined(separator: "|"))).*$"#
        static let insolubleFibre = #"^.*(\#(insolubleFibreOptions.joined(separator: "|"))).*$"#
        
        static let dietaryFibre = #"^(?=\#(dietaryFibreOnly))(?!\#(solubleFibre))(?!\#(insolubleFibre)).*$"#
        
        /// Negative lookbehind makes sure starch isn't preceded by tapioca
        static let starch = #"^(of which |)starch$"#
        
        static let totalFatOptions = [
            "fa(t|i)", "fett", "grassi", "lipidos", "grasa total", "grasimi"
        ]

        static let saturatedFatOptions = [
            "saturated",
            "satuwed", /// Vision typo
            "saturates",
            "of which saturates", "saturi", "saturados", "gras satures", "sat. fat", "kwasy nasycone", "grasi saturati", "sociosios"
        ]

        static let totalFat = #"^.*(\#(totalFatOptions.joined(separator: "|"))).*$"#
        static let saturatedFatOnly = #"^.*(\#(saturatedFatOptions.joined(separator: "|"))).*$"#
        static let transFat = #"^.*trans.*$"#
        static let monounsaturatedFat = #"^.*mono(-|)unsaturat.*$"#
        static let polyunsaturatedFat = #"^.*poly(-|)unsaturat.*$"#

        static let saturatedFat = #"^(?=\#(saturatedFatOnly))(?!\#(monounsaturatedFat))(?!\#(polyunsaturatedFat)).*$"#

        static let fat = #"^(?=\#(totalFat))(?!\#(saturatedFat))(?!\#(transFat))(?!\#(polyunsaturatedFat))(?!\#(monounsaturatedFat)).*$"#

        static let cholesterol = #"cholest"#
        
        static func vitamin(_ letter: String) -> String {
            #"vit(amin[ ]+|\.[ ]*|[ ]+)\#(letter)( |$)"#
        }
    }
}

extension String {
    var cleanedAttributeString: String {
        var cleaned = trimmingWhitespaces
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

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
        case .tableElementNutritionFacts:
            return "Nutrition Facts"
        case .tableElementSkippable:
            return "Vitamins & Minerals"
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
        case .polyols:
            return "Polyols"
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
            
        case .thiamin:
            return "Thiamin"
        case .riboflavin:
            return "Riboflavin"
        case .niacin:
            return "Niacin"
        case .zinc:
            return "Zinc"
        case .folate:
            return "Folate"
        case .folicAcid:
            return "Folic Acid"
        case .vitaminB1:
            return "Vitamin B1"
        case .vitaminB12:
            return "Vitamin B12"
        case .solubleFibre:
            return "Soluble Fibre"
        case .insolubleFibre:
            return "Insoluble Fibre"
        }
    }
}
