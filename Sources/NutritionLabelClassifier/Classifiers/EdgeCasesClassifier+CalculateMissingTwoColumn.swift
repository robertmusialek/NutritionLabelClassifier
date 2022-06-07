import Foundation
import VisionSugar

extension Array where Element == Observation {
    func forAttribute(_ attribute: Attribute) -> Observation? {
        first(where: { $0.attribute == attribute })
    }
    var containsHeaderTypesForBothColumns: Bool {
        contains(attribute: .headerType1)
        && contains(attribute: .headerType2)
    }
}
extension Observation {
    var hasOneValueMissing: Bool {
        (valueText1 != nil && valueText2 == nil)
        || (valueText1 == nil && valueText2 != nil)
    }
}
extension EdgeCasesClassifier {

    func calculateMissingValuesUsingRatioInTwoColumn() {
        
        guard observations.contains(attribute: .headerType1),
              observations.contains(attribute: .headerType2) else {
            return
        }
        
        guard let ratio = ratioOfValues else {
            return
        }
        
        for observation in observations {
            guard observation.hasOneValueMissing else {
                continue
            }
            
            if let value1 = observation.value1?.amount {
                let value2 = value1 / ratio
                observations.modifyObservation(observation, withValue2Amount: value2)
            }
            else if let value2 = observation.value2?.amount {
                let value1 = value2 * ratio
                observations.modifyObservation(observation, withValue1Amount: value1)
            }
            
        }
    }
    
    
    /// Ratio of `value1/value2`
    var ratioOfValues: Double? {
        var ratio: Double
        if let ratioUsingHeaders = ratioUsingHeaders {
            ratio = ratioUsingHeaders
        } else {
            guard let ratioUsingValues = ratioUsingValues else {
                return nil
            }
            ratio = ratioUsingValues
        }
        return ratio
    }

    /**
     Calculate the ratio between Header 1 and 2 values if they are in the same unit
         - for e.g. one is `.per100g` and the other is `.perServing` with a `.headerServingUnit` of `g` (do the same for `ml`)
     */
    var ratioUsingHeaders: Double? {
        guard let type1 = observations.forAttribute(.headerType1)?.headerType,
              let type2 = observations.forAttribute(.headerType2)?.headerType,
              let servingAmount = observations.forAttribute(.headerServingAmount)?.double,
              let servingUnit = observations.forAttribute(.headerServingUnit)?.unit
        else {
            return nil
        }
        
        switch (type1, type2) {
        case (.per100g, .perServing), (.perServing, .per100g):
            guard servingUnit == .g else { return nil }
        case (.per100ml, .perServing), (.perServing, .per100ml):
            guard servingUnit == .ml else { return nil }
        default:
            break
        }
        
        switch (type1, type2) {
        case (.per100g, .perServing), (.per100ml, .perServing):
            return 100.0/servingAmount
        case (.perServing, .per100g) , (.perServing, .per100ml):
            return servingAmount/100.0
        default:
            return nil
        }
    }
    
    /**
     Calculate the ratio between `value` and `value2` for nutrients that have them available
     
     Do this by getting an array of them, then statistically determine the mode of the set of ratios after rounding them off to the nearest integer
         1. This seems ideal, as we’ll be getting `4` as the valid ratio in this case
         2. We could take this one step further, filter out these ‘valid’ values and calculate the average of their actual (double) values.
     */
    var ratioUsingValues: Double? {
        var ratios: [Int] = []
        for observation in observations {
            guard let value1 = observation.value1?.amount,
                  let value2 = observation.value2?.amount
            else {
                continue
            }
            
            let ratio = value1/value2
            guard ratio > 0 else {
                continue
            }
            ratios.append(Int(ratio.rounded()))
        }
        //TODO: Return Mode of array of ratios
        return nil
    }
    
}

extension Observation {

    var unit: NutritionUnit? {
        guard let string = string else {
            return nil
        }
        return NutritionUnit(string: string)
    }

    var headerType: HeaderType? {
        guard let string = string else {
            return nil
        }
        return HeaderType(rawValue: string)
    }
}
