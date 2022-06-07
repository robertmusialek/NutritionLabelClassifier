import Foundation
import VisionSugar

extension RecognizedText {
//    var nutrientArtefacts: [NutrientArtefact] {
//        getNutrientArtefacts()
//    }
    
    func getNutrientArtefacts(for attribute: Attribute? = nil, observationBeingExtracted: Observation? = nil, extractedObservations: [Observation] = []) -> [NutrientArtefact] {
        var arrays: [[NutrientArtefact]] = []
        for candidate in candidates {
            arrays.append(nutrientArtefacts(for: candidate))
        }
        
        if let selection = heuristicSelectionOfValueWithUnit(from: arrays) {
            return selection
        }
        
        if let selection = heuristicSelectionOfValidValueForChildAttribute(from: arrays, for: attribute, observationBeingExtracted: observationBeingExtracted, extractedObservations: extractedObservations) {
            return selection
        }
        
        /// Default is to always return the first array if none of the heuristics picked another candidate
        return arrays.first(where: { $0.count > 0 }) ?? []
    }
    
    func nutrientArtefacts(for string: String) -> [NutrientArtefact] {
        
        var array: [NutrientArtefact] = []
        var string = string
        
        var isExpectingCalories: Bool = false
        
        while string.count > 0 {
            /// First check if we have a value at the start of the string
            if let valueSubstring = string.valueSubstringAtStart,
               /// If we do, extract it from the string and add its corresponding `Value` to the array
                var value = Value(fromString: valueSubstring) {
                
                /// **Heuristic** for detecting when energy is detected with the phrase "Calories", in which case we manually assign the `kcal` unit to the `Value` matched later.
                if isExpectingCalories {
                    if value.unit == nil {
                        value.unit = .kcal
                    }
                    /// Reset this once a value has been read after the energy attribute
                    isExpectingCalories = false
                }
                
                string = string.replacingFirstOccurrence(of: valueSubstring, with: "").trimmingWhitespaces
                
                let artefact = NutrientArtefact(value: value, textId: id)
                array.append(artefact)

            /// Otherwise, get the string component up to and including the next numeral
            } else if let substring = string.substringUpToFirstNumeral {
                
                /// Check if it matches any prepositions or attributes (currently picks prepositions over attributes for the entire substring)
                if let attribute = Attribute(fromString: substring) {
                    let artefact = NutrientArtefact(attribute: attribute, textId: id)
                    array.append(artefact)
                    
                    /// Reset this whenever a new attribute is reached
                    isExpectingCalories = false

                    /// **Heuristic** for detecting when energy is detected with the phrase "Calories", in which case we manually assign the `kcal` unit to the `Value` matched later.
                    if attribute == .energy && substring.matchesRegex(Attribute.Regex.calories) {
                        isExpectingCalories = true
                    }
                    
                } else  if let preposition = Preposition(fromString: substring) {
                    let artefact = NutrientArtefact(preposition: preposition, textId: id)
                    array.append(artefact)
                }
//                } else if let attribute = Attribute(fromString: substring) {
//                    let artefact = Artefact(attribute: attribute, textId: id)
//                    array.append(artefact)
//                }
                string = string.replacingFirstOccurrence(of: substring, with: "").trimmingWhitespaces
            } else {
                break
            }
        }
        return array
    }
}

//MARK: - Heuristic Selections
extension RecognizedText {
    
    /** If the first array's first element is a value without a unit, but one of the next candidates has a single value *with a unit*—pick the first one we encounter
     */
    func heuristicSelectionOfValueWithUnit(from arrays: [[NutrientArtefact]]) -> [NutrientArtefact]? {
        guard arrays.count > 1 else { return nil }
        guard let value = arrays.first?.first?.value, value.unit == nil else {
            return nil
        }
        for array in arrays.dropFirst() {
            if array.count == 1, let value = array.first?.value, value.unit != nil {
                return array
            }
        }
        return nil
    }
    
    /** Filters out the `Value`s containing `Unit`s, and if we have multiple of them *and* the attribute we're getting (if provided) is a child element of another attribute (ie. its value should be less than its), *and* we also have extracted the parent attribute earlier—we will choose the first value that is less than or equal to the parents value.
     
        For example: if VisionKit misreads `1.4g` as `11.4g` for `.saturatedFat`, and submits both strings as candidates, and we happen to have `.fat` set as `2.2g`—we would choose `1.4g` over `11.4g`
     */
    func heuristicSelectionOfValidValueForChildAttribute(from arrays: [[NutrientArtefact]], for attribute: Attribute? = nil, observationBeingExtracted: Observation? = nil, extractedObservations: [Observation] = []) -> [NutrientArtefact]?
    {
        guard arrays.count > 1 else { return nil }
        
        /// Make sure we have an attribute provided, and that it does have a parent attribute for which we have already extracted a row first.
        guard let attribute = attribute,
              let parentAttribute = attribute.parentAttribute,
              let parentObservation = extractedObservations.first(where: { $0.attributeText.attribute == parentAttribute })
        else {
            return nil
        }
        
        /// Grab the respective `Value` of the parent `Row` based on what we're currently grabbing (as comparisons across rows make no sense).
        let parentValue: Value?
        if observationBeingExtracted?.valueText1 != nil {
            parentValue = parentObservation.valueText2?.value
        } else {
            parentValue = parentObservation.valueText1?.value
        }
        guard let parentValue = parentValue else { return nil }

        /// Now filter out all the single unit-based value artefact arrays
        let artefactsOfSingleValuesWithUnits = arrays.filter {
            $0.count == 1
//            && $0.first?.value?.unit != nil
            && $0.first?.value?.unit == parentValue.unit
        }
        
        /// Make sure we have at least 2 to pick from before proceeding
        guard artefactsOfSingleValuesWithUnits.count > 1 else { return nil }
        
        /// Now go through each in order, and pick the first that is less than or equal to its parents amount
        /// **This should filter out any erraneously recognized values that are greater than the parent's**
        for array in artefactsOfSingleValuesWithUnits {
            if let amount = array.first?.value?.amount,
               amount <= parentValue.amount {
                return array
            }
        }
        
        return nil
    }
}
