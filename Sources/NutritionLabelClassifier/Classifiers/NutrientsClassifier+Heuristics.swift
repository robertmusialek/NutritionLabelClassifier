import Foundation
import VisionSugar

extension Array where Element == Observation {
    
    var twoColumnedNutrientObservations: [Observation] {
        filter {
            $0.attribute.isNutrientAttribute
            && $0.valueText1 != nil
            && $0.valueText2 != nil
        }
    }

    func checkIfMostNutrientsHave(smallerValue1: Bool) -> Bool {
        var numberOfObservationsWithASmallerValue1: Int = 0
        var numberOfObservationsWithASmallerValue2: Int = 0
        for observation in twoColumnedNutrientObservations {
            guard let value1 = observation.value1, let value2 = observation.value2 else {
                continue
            }
            if value1.amount < value2.amount {
                numberOfObservationsWithASmallerValue1 += 1
            } else if value2.amount < value1.amount {
                numberOfObservationsWithASmallerValue2 += 1
            }
        }
        if smallerValue1 {
            return numberOfObservationsWithASmallerValue1 > numberOfObservationsWithASmallerValue2
        }
        if !smallerValue1 {
            return numberOfObservationsWithASmallerValue2 > numberOfObservationsWithASmallerValue1
        }
        return false
    }
    
    var mostNutrientsHaveSmallerValue1: Bool {
        checkIfMostNutrientsHave(smallerValue1: true)
    }
    var mostNutrientsHaveSmallerValue2: Bool {
        checkIfMostNutrientsHave(smallerValue1: false)
    }
    
    var nutrientsWithSmallerValue2: [Observation] {
        twoColumnedNutrientObservations.filter {
            guard let value1 = $0.value1, let value2 = $0.value2 else { return false }
            return value2.amount < value1.amount
        }
    }

    var nutrientsWithSmallerValue1: [Observation] {
        twoColumnedNutrientObservations.filter {
            guard let value1 = $0.value1, let value2 = $0.value2 else { return false }
            return value1.amount < value2.amount
        }
    }
}

extension Observation {
    var smallerValue2: Bool {
        guard let value1 = value1, let value2 = value2 else { return false }
        return value2.amount < value1.amount
    }
    
    var smallerValue1: Bool {
        guard let value1 = value1, let value2 = value2 else { return false }
        return value1.amount < value2.amount
    }
}
extension NutrientsClassifier {
    
//    func checkPostExtractionHeuristics() {
//        clearErraneousValue2Extractions()
//        copyMissingZeroValues()
//        correctMissingDecimalPlaces()
//    }
//
//    /** **Release 0.0.117** Correct missing decimal places by first finding values that don't compare to the other column as does the average observation (ie. its smalle or larger than the other, while most others are the opposite)—then attempting to correct these values by either:
//     1. Appending a decimal place in the middle if it happens to be a 2-digit integer
//     2. Using the average ratio of the values between both columns (in the correct observations) to extrapolate what the value should be
//     */
//    func correctMissingDecimalPlaces() {
//        if observations.mostNutrientsHaveSmallerValue2 {
//            for index in observations.indices {
//                guard observations[index].smallerValue1,
//                      let value2 = observations[index].value2,
//                      let value1 = observations[index].value1
//                else { continue }
//                
//                if let newValue = value2.decrementByAdditionOfDecimalPlace(toBeLessThan: value1) {
//                    observations[index].valueText2?.value = newValue
//                }
//                //TODO: Implement fallback
//                /**
//                 - As a fallback
//                     - Get the average ratio between all the valid rows (ie. that satisfy the comparison condition)
//                     - Now apply this ratio to the incorrect observations to correct the values.
//                 */
//            }
//        }
//        
//        if observations.mostNutrientsHaveSmallerValue1 {
//            for index in observations.indices {
//                guard observations[index].smallerValue2,
//                      let value2 = observations[index].value2,
//                      let value1 = observations[index].value1
//                else { continue }
//                
//                if let newValue = value1.decrementByAdditionOfDecimalPlace(toBeLessThan: value2) {
//                    observations[index].valueText2?.value = newValue
//                }
//                //TODO: Implement fallback (see above case)
//            }
//        }
//    }
//
//    /// If more than half of value2 is empty, clear it all, assuming we have erraneous reads
//    func clearErraneousValue2Extractions() {
//        if observations.percentageOfNilValue2 > 0.5 {
//            observations = observations.clearingValue2
//        }
//    }
//    
//    /// If we have two values worth of data and any of the cells are missing where one value is 0, simply copy that across
//    func copyMissingZeroValues() {
//        if observations.hasTwoColumnsOfValues {
//            for index in observations.indices {
//                let observation = observations[index]
//                if observation.valueText2 == nil, let value1 = observation.valueText1, value1.value.amount == 0 {
//                    observations[index].valueText2 = value1
//                }
//            }
//        }
//    }
    
    func heuristicRecognizedTextIsPartOfAttribute(_ recognizedText: RecognizedText) -> Bool {
        recognizedText.string.lowercased() == "vitamin"
    }
}

extension Value {
    func decrementByAdditionOfDecimalPlace(toBeLessThan value: Value) -> Value? {
        /// If the `amount` is not a two-digit Integer, or its already less than or equal to `value`, return `nil`
        guard amount >= value.amount, amount >= 10, amount < 100, amount.isInt else {
            return nil
        }

        var string = "\(Int(amount))"
        string.insert(".", at: string.index(string.startIndex, offsetBy: 1))
        
        /// If we've somehow muddled up the numerical value in its string representation, or the `newAmount` is *still* not less than `value`, return `nil`
        guard let newAmount = Double(string), newAmount < value.amount else {
            return nil
        }
        
        return Value(amount: newAmount, unit: self.unit)
    }
}
