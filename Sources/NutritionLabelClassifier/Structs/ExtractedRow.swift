import SwiftUI
import VisionSugar

extension ValuesText {
    var containsLessThanPrefix: Bool {
        text.string.lowercased().contains("less than")
    }
}
struct ExtractedRow {
    let attributeText: AttributeText
    var valuesTexts: [ValuesText?]
    
    var firstValue: Value? {
        valuesTexts.first??.values.first
    }
    
    var ratioColumn1To2: Double? {
        guard valuesTexts.count == 2,
              let valuesText1 = valuesTexts[0],
              let valuesText2 = valuesTexts[1],
              !valuesText1.containsLessThanPrefix,
              !valuesText2.containsLessThanPrefix,
              let amount1 = valuesText1.values.first?.amount,
              let amount2 = valuesText2.values.first?.amount,
              amount2 != 0
        else {
            return nil
        }
        return amount1/amount2
    }
    
    var valuesTextsContainLessThanPrefix: Bool {
        guard valuesTexts.count == 2,
              let valuesText1 = valuesTexts[0],
              let valuesText2 = valuesTexts[1]
        else {
            return false
        }
        return valuesText1.containsLessThanPrefix || valuesText2.containsLessThanPrefix
    }
    
    var hasNilValues: Bool {
        valuesTexts.allSatisfy({ $0 == nil })
    }
    
    var hasOneMissingValue: Bool {
        singleMissingValueIndex != nil
    }
    
    var hasMismatchedUnits: Bool {
        guard let value1 = value1, let value2 = value2 else {
            return false
        }
        return value1.unit != value2.unit
    }
    
    var value1: Value? {
        valuesTexts[0]?.values.first
    }
    var value2: Value? {
        guard valuesTexts.count > 1 else { return nil }
        return valuesTexts[1]?.values.first
    }

    var singleMissingValueIndex: Int? {
        guard valuesTexts.count == 2 else { return nil }
        if valuesTexts[0] != nil && valuesTexts[1] == nil {
            return 1
        }
        if valuesTexts[1] != nil && valuesTexts[0] == nil {
            return 0
        }
        return nil
    }
    
    var hasZeroValues: Bool {
        valuesTexts.allSatisfy({ $0?.values.first?.amount == 0 })
    }
}
