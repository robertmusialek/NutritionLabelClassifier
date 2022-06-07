import Foundation
import VisionSugar

let defaultUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

extension Array where Element == Observation {
    func value1(for attribute: Attribute) -> Value? {
        first(where: { $0.attribute == attribute })?.value1
    }
}

class EdgeCasesClassifier: Classifier {
    let recognizedTexts: [RecognizedText]
    var observations: [Observation]

    var pendingObservations: [Observation] = []
    var observationBeingExtracted: Observation? = nil
    var discarded: [RecognizedText] = []

    init(recognizedTexts: [RecognizedText], observations: [Observation]) {
        self.recognizedTexts = recognizedTexts
        self.observations = observations
    }
    
    static func observations(from recognizedTexts: [RecognizedText], priorObservations observations: [Observation]) -> [Observation] {
        EdgeCasesClassifier(recognizedTexts: recognizedTexts, observations: observations)
            .getObservations()
    }
    
    func getObservations() -> [Observation] {
        
        copyMissingZeroValues()
        correctMissingDecimalPlaces()

        findMissedServingAmount()
        findMissingHeaderType1()
        
        calculateMissingMacroOrEnergyInSingleColumnOfValues()
        
        calculateMissingValuesUsingRatioInTwoColumn()
        correctMacroOrEnergyUsingRatioInTwoColumn()
        
        clearErraneousValue2Extractions()

        return observations
    }
        
    /// If we have only one column of values, and haven’t already assigned `.headerType1`, look for the text `Amount Per Serving` and then manually set `.headerType1` as `.perServing` if found.
    func findMissingHeaderType1() {
        guard !observations.hasTwoColumnsOfValues, !observations.contains(attribute: .headerType1) else {
            return
        }
        for recognizedText in recognizedTexts {
            if let headerType = HeaderType(string: recognizedText.string),
               let observation = Observation(headerType: headerType,
                                             for: .headerType1,
                                             recognizedText: recognizedText)
            {
                observations.append(observation)
            }
        }
    }
    
    func findMissedServingAmount() {
        /// If we haven't got a serving amount yet
        guard !observations.contains(attribute: .servingAmount),
              !observations.contains(attribute: .servingUnit),
              !observations.contains(attribute: .headerServingAmount),
              !observations.contains(attribute: .headerServingUnit)
        else {
            return
        }
        
        /// Look for a `Value` within brackets such as `(170g)` (that hasn't been used already) and assign that.
        for recognizedText in recognizedTexts {
            let regex = #"\(([0-9]*)[ ]*g\)"#
//            let regex = #"([0-9]*)g"#
            let groups = recognizedText.string.capturedGroups(using: regex)
            if groups.count == 2,
               let amount = Double(groups[1]),
               let amountObservation = Observation(
                    double: amount,
                    attribute: .servingAmount,
                    recognizedText: recognizedText
               ),
               let unitObservation = Observation(
                    unit: .g,
                    attribute: .servingUnit,
                    recognizedText: recognizedText
               )
            {
                observations.append(amountObservation)
                observations.append(unitObservation)
            }
        }
    }
    
    /** **Release 0.0.117** Correct missing decimal places by first finding values that don't compare to the other column as does the average observation (ie. its smalle or larger than the other, while most others are the opposite)—then attempting to correct these values by either:
     1. Appending a decimal place in the middle if it happens to be a 2-digit integer
     2. Using the average ratio of the values between both columns (in the correct observations) to extrapolate what the value should be
     */
    func correctMissingDecimalPlaces() {
        if observations.mostNutrientsHaveSmallerValue2 {
            for index in observations.indices {
                guard observations[index].smallerValue1,
                      let value2 = observations[index].value2,
                      let value1 = observations[index].value1
                else { continue }
                
                if let newValue = value2.decrementByAdditionOfDecimalPlace(toBeLessThan: value1) {
                    observations[index].valueText2?.value = newValue
                }
                //TODO: Implement fallback
                /**
                 - As a fallback
                     - Get the average ratio between all the valid rows (ie. that satisfy the comparison condition)
                     - Now apply this ratio to the incorrect observations to correct the values.
                 */
            }
        }
        
        if observations.mostNutrientsHaveSmallerValue1 {
            for index in observations.indices {
                guard observations[index].smallerValue2,
                      let value2 = observations[index].value2,
                      let value1 = observations[index].value1
                else { continue }
                
                if let newValue = value1.decrementByAdditionOfDecimalPlace(toBeLessThan: value2) {
                    observations[index].valueText2?.value = newValue
                }
                //TODO: Implement fallback (see above case)
            }
        }
        
        for observation in observations {
            if let parentAttribute = observation.attribute.parentAttribute,
               let parent = observations.first(where: { $0.attribute == parentAttribute })
            {
                if observation.hasLargerValue1Than(parent) == true {
                    pickAnotherCandidateForValue1Of(
                        observation,
                        lessThanOrEqualTo: parent.value1!.amount)
                }
                
                if observation.hasLargerValue2Than(parent) == true {
                    pickAnotherCandidateForValue2Of(
                        observation,
                        lessThanOrEqualTo: parent.value1!.amount)
                }
            }
        }
    }

    /// If more than half of value2 is empty, clear it all, assuming we have erraneous reads
    func clearErraneousValue2Extractions() {
        if observations.percentageOfNilValue2 > 0.5
            || !observations.contains(attribute: .headerType2)
        {
            observations = observations.clearingValue2
        }
    }
    
    /// If we have two values worth of data and any of the cells are missing where one value is 0, simply copy that across
    func copyMissingZeroValues() {
        if observations.hasTwoColumnsOfValues {
            for index in observations.indices {
                let observation = observations[index]
                if observation.valueText2 == nil, let value1 = observation.valueText1, value1.value.amount == 0 {
                    observations[index].valueText2 = value1
                }
            }
        }
    }
    
    //TODO: Modularize both of these
    func pickAnotherCandidateForValue1Of(_ observation: Observation, lessThanOrEqualTo parentAmount: Double) {
        guard let id = observation.valueText1?.textId,
              let recognizedText = recognizedTexts.withId(id),
              let validValue = recognizedText.value(lessThanOrEqualTo: parentAmount)
        else {
            return
        }
        
        let newValue = Value(amount: validValue.amount, unit: observation.attribute.defaultUnit)
        observations.modifyObservation(observation, withValue1: newValue)
    }
    func pickAnotherCandidateForValue2Of(_ observation: Observation, lessThanOrEqualTo parentAmount: Double) {
        guard let id = observation.valueText2?.textId,
              let recognizedText = recognizedTexts.withId(id),
              let validValue = recognizedText.value(lessThanOrEqualTo: parentAmount)
        else {
            return
        }
        
        let newValue = Value(amount: validValue.amount, unit: observation.attribute.defaultUnit)
        observations.modifyObservation(observation, withValue2: newValue)
    }
}

extension RecognizedText {
    func value(lessThanOrEqualTo ceilingAmount: Double) -> Value? {
        for candidate in candidates {
            let artefacts = self.nutrientArtefacts(for: candidate)
            
            //TODO: Handle strings with multiple attributes/values in them
            for artefact in artefacts {
                if let value = artefact.value, value.amount <= ceilingAmount {
                    return value
                }
            }
        }
        return nil
    }
}

extension Array where Element == RecognizedText {
    func withId(_ id: UUID) -> RecognizedText? {
        first(where: { $0.id == id })
    }
}

extension Array where Element == Observation {
    
    func containsObservationWithTextId(_ id: UUID) -> Bool {
        contains(where: { $0.containsTextId(id) })
    }
    
    //TODO: Modularize both of these
    mutating func modifyObservation(_ observation: Observation, withValue1 newValue1: Value) {
        guard let index = self.firstIndex(where: { $0.attribute == observation.attribute }) else { return }
        let newObservation = Observation(
            attributeText: observation.attributeText,
            valueText1: ValueText(value: newValue1,
                                  textId: observation.valueText1?.textId ?? defaultUUID),
            valueText2: observation.valueText2,
            doubleText: nil, stringText: nil)
        self[index] = newObservation
    }
    mutating func modifyObservation(_ observation: Observation, withValue2 newValue2: Value) {
        guard let index = self.firstIndex(where: { $0.attribute == observation.attribute }) else { return }
        let newObservation = Observation(
            attributeText: observation.attributeText,
            valueText1: observation.valueText1,
            valueText2: ValueText(value: newValue2,
                                  textId: observation.valueText2?.textId ?? defaultUUID),
            doubleText: nil, stringText: nil)
        self[index] = newObservation
    }
    
    //TODO: Modularize both of these
    mutating func modifyObservation(_ observation: Observation, withValue1Amount newAmount: Double) {
        modifyObservation(
            observation,
            withValue1: Value(amount: newAmount, unit: observation.value2?.unit)
        )
    }
    mutating func modifyObservation(_ observation: Observation, withValue2Amount newAmount: Double) {
        modifyObservation(
            observation,
            withValue2: Value(amount: newAmount, unit: observation.value1?.unit)
        )
    }

}

extension Observation {
    
    var textIds: [UUID] {
        [attributeText.textId,
         valueText1?.textId,
         valueText2?.textId,
         doubleText?.textId,
         stringText?.textId]
            .compactMap { $0 }
    }
    
    func containsTextId(_ id: UUID) -> Bool {
        textIds.contains(id)
    }
    
    func hasLargerValue1Than(_ observation: Observation) -> Bool? {
        if let value1 = value1 {
            
            guard let otherValue1 = observation.value1,
                    otherValue1.unit == value1.unit
            else { return nil }
            
            if value1.amount > otherValue1.amount {
                return true
            }
        } else {
            guard observation.value1 == nil else { return nil }
        }
        return false
    }
    
    func hasLargerValue2Than(_ observation: Observation) -> Bool? {
        if let value2 = value2 {
            
            guard let otherValue2 = observation.value2,
                  otherValue2.unit == value2.unit
            else { return nil }
            
            if value2.amount > otherValue2.amount {
                return true
            }
        } else {
            guard observation.value2 == nil else { return nil }
        }
        return false
    }
    
    /// Returns `true` if the values are greater than observations
    /// Also returns `nil` if the values don't match in number (ie. both don't have either 1 or 2 values)
    func hasLargerValuesThan(_ observation: Observation) -> Bool? {
        guard let hasLargerValue1 = hasLargerValue1Than(observation),
              let hasLargerValue2 = hasLargerValue2Than(observation)
        else {
            return nil
        }
        return hasLargerValue1 && hasLargerValue2
    }
}
