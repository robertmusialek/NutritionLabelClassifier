import Foundation

struct Nutrient {
    let attribute: Attribute
    let value: Value
}

extension String {
    var containsInlineNutrients: Bool {
        !nutrients.isEmpty
    }
    
    var nutrients: [Nutrient] {
        
        var nutrients: [Nutrient] = []
        var setAsideAttribute: Attribute? = nil
        var setAsideValue: Value? = nil
        var saveNextValue: Bool = false
        let artefacts = self.nutrientArtefacts(textId: defaultUUID)
        
        func appendNutrientWith(attribute: Attribute, value: Value) {
            nutrients.append(Nutrient(attribute: attribute, value: value))
            setAsideAttribute = nil
            setAsideValue = nil
        }

        for i in artefacts.indices {
            
            let artefact = artefacts[i]
            
            if artefact.isIncludesPreposition {
                saveNextValue = true
            }
            
            /// If we encounter an `Attribute`
            if let attribute = artefact.attribute, attribute.isNutrientAttribute {
                if let value = setAsideValue {
                    /// … and we have a `Value` set aside, add the `Nutrient`
                    appendNutrientWith(attribute: attribute, value: value)
                } else if attribute == .addedSugar,
                          artefact == artefacts.last,
                          i > 0,
                          let value = artefacts[i-1].value
                {
                    /// … (**Heuristic**) and this is the last artefact with the previous one being a value
                    appendNutrientWith(attribute: attribute, value: value)
                } else {
                    /// otherwise, set the `Attribute` aside
                    setAsideAttribute = attribute
                }
            }
            /// If we encounter a `Value`
            else if let value = artefact.value {
                if let attribute = setAsideAttribute {
                    /// … and have an `Attribute` set aside, add the `Nutrient`
                    appendNutrientWith(attribute: attribute, value: value)
                } else if saveNextValue {
                    /// … otherwise, if we've set the `saveNextValue` flag, set the `Value` aside and reset the flag
                    setAsideValue = value
                    saveNextValue = false
                }
            }
        }
        
        if !nutrients.isEmpty {
            print("Nutrients for '\(self)': \(nutrients.description)")
        }
        
        return nutrients
    }
}

extension Nutrient: CustomStringConvertible {
    var description: String {
        "\(attribute.rawValue): \(value.description)"
    }
}

extension NutrientArtefact {
    var isIncludesPreposition: Bool {
        guard let preposition = preposition else {
            return false
        }
        return preposition == .includes
    }
}
